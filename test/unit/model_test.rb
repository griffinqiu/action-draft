# frozen_string_literal: true

require "test_helper"

class ActionDraft::ModelTest < ActiveSupport::TestCase
  test "saving attributes" do
    message = Message.create(
      title: "Hello world",
      content: "This is message content.",
      draft_title: "Hello world draft",
      draft_content: "This is draft message content.",
    )

    assert_equal "Hello world", message.title
    assert_equal "Hello world draft", message.draft_title.to_s
    assert_equal "This is message content.", message.content
    assert_equal "This is draft message content.", message.draft_content.to_s

    drafts = ActionDraft::Content.where(record: message)
    assert_equal 2, drafts.size

    assert_equal message.draft_title, ActionDraft::Content.where(record: message, name: "title").take
    assert_equal message.draft_content, ActionDraft::Content.where(record: message, name: "content").take
  end

  test "without draft" do
    message = Message.create!(title: "Greetings")
    assert message.draft_title.nil?
    assert message.draft_title.blank?
    assert_not message.draft_title.present?
  end

  test "with blank content" do
    message = Message.create!(draft_content: "")
    assert_not message.draft_content.nil?
    assert message.draft_content.blank?
    assert_not message.draft_content.present?
  end

  test "with_drafts" do
    10.times do |i|
      Message.create(
        title: "Hello world #{i}",
        content: "This is message content #{i}.",
        draft_title: "Hello world draft #{i}",
        draft_content: "This is draft message content #{i}.",
      )
    end

    assert_equal 10, Message.count
    # SELECT * FROM messages
    # SELECT * FROM action_draft_contents WHERE name = "draft_title" AND record_id IN (?)
    # SELECT * FROM action_draft_contents WHERE name = "draft_content" AND record_id IN (?)
    assert_queries(3) do
      messages = Message.with_drafts.all.to_a
      draft_titles = messages.collect(&:draft_title)
      draft_contents = messages.collect(&:draft_content)
    end
  end
end