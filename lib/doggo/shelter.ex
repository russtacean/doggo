defmodule Doggo.Shelter do
  use Ash.Domain,
    otp_app: :doggo

  resources do
    resource Doggo.Shelter.Location do
      define :create_location, action: :create
      define :list_locations, action: :read
      define :list_active_locations, action: :list_active
      define :get_location, action: :read, get_by: [:id]
      define :update_location, action: :update
      define :destroy_location, action: :destroy
    end

    resource Doggo.Shelter.Enclosure do
      define :create_enclosure_at_location, action: :create
      define :list_enclosures, action: :read
      define :list_enclosures_for_location, action: :list_for_location, args: [:location_id]
      define :get_enclosure, action: :read, get_by: [:id]
      define :update_enclosure, action: :update
      define :destroy_enclosure, action: :destroy
    end

    resource Doggo.Shelter.ScheduledShift do
      define :create_scheduled_shift_at_location, action: :create
      define :list_scheduled_shifts, action: :read

      define :list_scheduled_shifts_for_location_and_date,
        action: :list_for_location_and_date,
        args: [:location_id, :date]

      define :list_upcoming_scheduled_shifts,
        action: :list_upcoming,
        args: [:location_id, :from_date]

      define :get_scheduled_shift, action: :read, get_by: [:id]
      define :update_scheduled_shift, action: :update
      define :destroy_scheduled_shift, action: :destroy
    end

    resource Doggo.Shelter.RecurringShift do
      define :create_recurring_shift, action: :create
      define :list_recurring_shifts, action: :read
      define :get_recurring_shift, action: :read, get_by: [:id]
      define :update_recurring_shift, action: :update
      define :destroy_recurring_shift, action: :destroy

      define :list_active_recurring_shifts_for_location_and_day,
        action: :active_for_location_and_day,
        args: [:location_id, :day_of_week, :date]
    end
  end
end
