defmodule Doggo.Shelter.RecurringShift do
  use Ash.Resource, otp_app: :doggo, domain: Doggo.Shelter, data_layer: AshPostgres.DataLayer

  postgres do
    table "recurring_shifts"
    repo Doggo.Repo

    references do
      reference :location, index?: true, on_delete: :delete
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:name, :day_of_week, :start_time, :end_time, :start_date, :end_date]

      argument :location, :uuid do
        allow_nil? false
      end

      change manage_relationship(:location, :location,
               type: :append_and_remove,
               on_lookup: :relate,
               value_is_key: :id
             )
    end

    update :update do
      require_atomic? false
      accept [:name, :day_of_week, :start_time, :end_time, :start_date, :end_date]
    end

    read :active_for_location_and_day do
      argument :location_id, :uuid do
        allow_nil? false
      end

      argument :day_of_week, :integer do
        allow_nil? false
      end

      argument :date, :date do
        allow_nil? false
      end

      prepare build(
                filter:
                  expr(
                    location_id == ^arg(:location_id) and day_of_week == ^arg(:day_of_week) and
                      (is_nil(start_date) or start_date <= ^arg(:date)) and
                      (is_nil(end_date) or end_date > ^arg(:date))
                  )
              )
    end
  end

  preparations do
    prepare build(sort: [start_time: :asc])
  end

  changes do
    change Doggo.Shelter.RecurringShift.OverlapCheck, on: [:create, :update]
  end

  validations do
    # Shelters don't have overnight shifts, so prevent this type of configuration by accident
    validate compare(:end_time, greater_than: :start_time) do
      message "must be after the start time"
    end

    validate compare(:end_date, greater_than: :start_date) do
      message "must be after the start date"
      where present([:start_date, :end_date])
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :day_of_week, :integer do
      allow_nil? false
      public? true
      constraints min: 1, max: 7
    end

    attribute :start_time, :time do
      allow_nil? false
      public? true
    end

    attribute :end_time, :time do
      allow_nil? false
      public? true
    end

    attribute :start_date, :date do
      allow_nil? true
      public? true
      description "First date this pattern is active (inclusive). nil means indefinite past."
    end

    attribute :end_date, :date do
      allow_nil? true
      public? true

      description "First date this pattern is no longer active (exclusive). nil means indefinite future."
    end

    timestamps()
  end

  relationships do
    belongs_to :location, Doggo.Shelter.Location do
      allow_nil? false
      attribute_public? true
    end
  end
end
