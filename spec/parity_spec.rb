require "spec_helper"

RSpec.describe "bin/parity.sh" do
  let(:script_path) { File.expand_path("../bin/parity.sh", __dir__) }

  def run_parity(number)
    `#{script_path} #{number}`.strip
  end

  describe "even numbers" do
    it "returns EVEN for 0" do
      expect(run_parity(0)).to eq("EVEN")
    end

    it "returns EVEN for 2" do
      expect(run_parity(2)).to eq("EVEN")
    end

    it "returns EVEN for 10" do
      expect(run_parity(10)).to eq("EVEN")
    end
  end

  describe "odd numbers" do
    it "returns ODD for 1" do
      expect(run_parity(1)).to eq("ODD")
    end

    it "returns ODD for 15" do
      expect(run_parity(15)).to eq("ODD")
    end
  end
end
