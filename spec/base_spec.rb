require File.join(File.dirname(__FILE__), "helpers")
require "sensu/extension"
require "logger"

describe "Sensu::Extension::Base" do
  include Helpers

  before do
    @extension = Sensu::Extension::Base.new
  end

  it "can provide the extension API" do
    @extension.should respond_to(:name, :description, :definition, :safe_run, :stop, :has_key?, :[])
  end

  it "can provide default method return values" do
    @extension.name.should eq("base")
    @extension.description.should eq("extension description (change me)")
    @extension.definition.should eq({:type => "extension", :name => "base"})
  end

  it "can have a logger" do
    @extension.logger = Logger.new("/dev/null")
    @extension.logger.formatter = Proc.new do |severity, datetime, progname, message|
      severity.should eq("INFO")
      message.should eq("test")
    end
    @extension.logger.info("test")
  end

  it "can have settings" do
    settings = {:foo => 1}
    @extension.settings = settings
    @extension.settings.should eq(settings)
  end

  it "can handle provided callbacks" do
    async_wrapper do
      callback = Proc.new do |output, status|
        output.should eq("noop")
        status.should eq(0)
        @extension.stop do
          async_done
        end
      end
      @extension.run(&callback)
    end
  end

  it "can pass event data to run" do
    async_wrapper do
      event = {:foo => 1}
      @extension.safe_run(event) do |output, status|
        output.should eq("noop")
        status.should eq(0)
        async_done
      end
    end
  end

  it "can provide hash like access to definition()" do
    @extension.has_key?(:type).should be_true
    @extension.has_key?(:name).should be_true
    @extension[:type].should eq("extension")
    @extension[:name].should eq("base")
  end

  it "can provide a list of decendant classes" do
    expected = [
      Sensu::Extension::Generic,
      Sensu::Extension::Check,
      Sensu::Extension::Mutator,
      Sensu::Extension::Handler
    ]
    Sensu::Extension::Base.descendants.should include(*expected)
  end
end
