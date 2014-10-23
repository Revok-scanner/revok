require File.dirname(__FILE__) + '/../helper.rb'
require 'core/module'
require 'test/core/ab_module/ab_module_non_init'
require 'test/core/ab_module/ab_module_non_run'
require 'test/core/ab_module/ab_module_pass_default'
require 'test/core/ab_module/ab_module_pass'

describe Revok::Module, "module abstract" do

	context "when initialize method is not implemented" do
		it "throws an exception" do
			expect { TestModule_NonInit.new }.to raise_error{ NotImplementedError }
		end
	end

	context "when run method is not implemented" do
		it "throws an exception" do
			test_module = TestModule_NonRun.new
			expect { test_module.run }.to raise_error{ NotImplementedError }
		end
	end

	context "when priority infomations are missing" do
		let(:default_module) { TestModule_Default.new }

		it "fills in the default module priority" do
			default_module.info["priority"].should == 10
		end

		it "fills in the default group name" do
			default_module.info["group_name"].should == "default"
		end

		it "fills in the default group priority" do
			default_module.info["group_priority"].should == 10
		end
	end

	context "when all infomations are valid" do
		let(:test_module) { TestModule.new }
		it "registers the name of a module" do
			test_module.name.should == "TestModule_Pass"
		end

		it "registers the priority of a module" do
			test_module.info["priority"].should == 11
		end

		it "registers the group name of a module" do
			test_module.info["group_name"].should == "test_group"
		end

		it "registers the group priority of a module" do
			test_module.info["group_priority"].should == 11
		end
	end
end
