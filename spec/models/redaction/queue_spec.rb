require 'spec_helper'

describe Redaction::Queue do
  FAKE_QUEUE_MAX = 2

  before { Redaction::Queue.stub(:queue_max).and_return(FAKE_QUEUE_MAX) }

  context '#notices' do
    it "returns the notices in review with the user" do
      user = User.new
      Notice.should_receive(:in_review).with(user).and_return(:some_notices)

      queue = new_queue(user)

      expect(queue.notices).to eq :some_notices
    end
  end

  context "#reload" do
    it "reloads the in-review notices" do
      stub_notices_in_review(3)
      queue = new_queue
      notices_before = queue.notices
      stub_notices_in_review(2)

      queue.reload

      expect(queue.notices).not_to eq notices_before
    end
  end

  context "#available_space" do
    it "returns the amount of space in the queue" do
      stub_notices_in_review(FAKE_QUEUE_MAX - 1)
      queue = new_queue

      expect(queue.available_space).to eq 1
    end
  end

  context '#full?/#empty?' do
    it "returns true/false when the queue is full" do
      stub_notices_in_review(FAKE_QUEUE_MAX)
      queue = new_queue

      expect(queue).to be_full
      expect(queue).not_to be_empty
    end

    it "returns false/false when the queue is partially full" do
      stub_notices_in_review(FAKE_QUEUE_MAX - 1)
      queue = new_queue

      expect(queue).not_to be_full
      expect(queue).not_to be_empty
    end

    it "returns false/true when the queue is empty" do
      stub_notices_in_review(0)
      queue = new_queue

      expect(queue).not_to be_full
      expect(queue).to be_empty
    end
  end

  private

  def stub_notices_in_review(n)
    notices = Array.new(n) { Notice.new }
    Notice.stub(:in_review).and_return(notices)
  end

  def new_queue(user = User.new)
    Redaction::Queue.new(user)
  end

end