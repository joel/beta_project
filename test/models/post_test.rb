require 'test_helper'

module HasDueDateAndOptionalTimeHelper

  # test_has_due_date_and_optional_time(Post, :due_date, :due_time)

  # We test this per model to ensure that there are no other interactions for
  # the model that interfere with this concern.
  def test_has_due_date_and_optional_time(model, date_attr, time_attr)
    model_name = model.name.underscore

    context "due_date and time" do

      should "not allow due_time to be set and due_date to be nil when created" do
        item = build_stubbed(model_name, date_attr => nil, time_attr => "22:00")
        assert_not item.valid?
        assert_includes item.errors, date_attr
      end

      should "not allow due_time to be set and due_date to be nil" do
        item = build(model_name, date_attr => nil)
        assert_nil item.public_send(date_attr)
        item.save!

        item.public_send("#{time_attr}=", "22:00")
        assert_not item.valid?
        assert_includes item.errors, date_attr
      end

      should "allow due_time to be nil if due_date is filled" do
        item = build(model_name, date_attr => "23/09/2014", time_attr => nil)
        assert item.valid?
        assert_not_nil item.send(date_attr)
        assert_equal 23, item.send(date_attr).hour
        assert_equal 59, item.send(date_attr).min
        assert_equal 59, item.send(date_attr).sec
      end

      should "set the end time to 23:59:59 if the due_time is not set" do
        item = build(model_name, date_attr => "23/09/2014", time_attr => nil)
        assert item.valid?
        assert_equal Time.zone.local(2014, 9, 23, 23, 59, 59), item.send(date_attr)
      end

      should "not allow an invalid date" do
        item = build_stubbed(model_name, date_attr => "I am not a date!", time_attr => "10:00")
        assert_not item.valid?
      end

      should "save after due_date and due_time have been deleted" do
        item = create(model_name, date_attr => Time.zone.now - 10, time_attr => "10:00")
        item.send("#{date_attr}=", nil)
        item.send("#{time_attr}=", nil)
        item.save
        assert item.valid?
      end

      should "set the correct time on the due date" do
        item = build_stubbed(model_name, date_attr => Time.zone.now, time_attr => "14:00")
        assert_equal "14:00", item.send(date_attr).strftime("%R")
      end

      context "due_time" do

        should "return the due time from the due date when set" do
          item = build_stubbed(model_name, date_attr => Time.zone.now)
          assert_not_nil item.send(time_attr)
        end

        should "return nil when the due date is not set" do
          item = build_stubbed(model_name, date_attr => nil)
          assert_nil item.send(time_attr)
        end

        should "return the due_time if set and ignore the due_date time" do
          date = Time.zone.local(2014, 2, 3, 10, 0, 0)
          item = model.new(date_attr => date, time_attr => "20:00")
          assert_equal "20:00", item.send(time_attr)
        end

        should "not return the due_time if all_day flag set to true" do
          date = Time.zone.local(2014, 2, 3, 10, 0, 0)

          assert_warn(StructuredWarnings::DeprecatedMethodWarning) do
            item = build_stubbed(model_name, date_attr => date, all_day: true)
            assert_nil item.send(time_attr)
          end
        end

      end

      context "time zone" do

        should "return different time when time zone changes" do
          item = Time.use_zone("London") do
            create(model_name, date_attr => "5/5/2014", time_attr => "14:00")
          end
          item.reload
          Time.use_zone("Fiji") do
            assert_equal "01:00", item.send(date_attr).strftime("%R")
            assert_equal "01:00", item.send(time_attr)
          end
        end

        context "sets times relative to summer/winter time zone" do

          setup do
            @with_same_zone = ->(&blk) {
              Time.use_zone("London") do
                blk.call
              end
            }

            @with_same_zone.call do
              @item1 = build_stubbed(model_name, date_attr => "5/5/2014", time_attr => "14:00")
              @item2 = build_stubbed(model_name, date_attr => "5/12/2014", time_attr => "14:00")
            end
          end

          should "return summer time zone for tasks created in propper period" do
            @with_same_zone.call do
              assert_equal "BST", @item1.send(date_attr).zone
            end
          end

          should "return winter time zone for tasks created in propper period" do
            @with_same_zone.call do
              assert_equal "GMT", @item2.send(date_attr).zone
            end
          end

          should "return equal relative hours" do
            @with_same_zone.call do
              assert_equal @item1.send(date_attr).strftime("%R"),
                           @item2.send(date_attr).strftime("%R")
            end
          end

        end

      end

    end

    context "all_day?" do

      should "set the all_day flag to true if no time is set" do
        item = model.new(date_attr => "23/09/2014", time_attr => nil)

        assert item.all_day?
      end

      should "set the all_day flag to false if time is set" do
        item = build_stubbed(model_name, date_attr => "23/09/2014", time_attr => "09:00")
        assert_not item.all_day?
      end

    end

    context "scopes" do

      context "due_today" do

        setup do
          @due_today_items = [
            create(model_name, date_attr => "3/1/2014"),
            create(model_name, date_attr => "3/1/2014", time_attr => "00:00"),
            create(model_name, date_attr => "3/1/2014", time_attr => "3:00"),
            create(model_name, date_attr => "3/1/2014", time_attr => "23:59")
          ]
          create(model_name, date_attr => "2/1/2014")
          create(model_name, date_attr => "2/1/2014", time_attr => "23:59")
          create(model_name, date_attr => "4/1/2014")
          create(model_name, date_attr => "4/1/2014", time_attr => "00:00")
          create(model_name)
        end

        should "return items due today only" do
          Timecop.freeze(Time.zone.local(2014, 1, 3, 14, 0)) do
            assert_same_elements @due_today_items, model.due_today
          end
        end

      end

    end
  end

end

class PostTest < ActiveSupport::TestCase

  extend HasDueDateAndOptionalTimeHelper

  test_has_due_date_and_optional_time(Post, :due_date, :due_time)
end
