defmodule Doggo.Shelter.ScheduledShift do
  use Ash.Resource, otp_app: :doggo, domain: Doggo.Shelter, data_layer: AshPostgres.DataLayer

  postgres do
    table "scheduled_shifts"
    repo Doggo.Repo

    references do
      reference :location, index?: true, on_delete: :delete
    end
  end

  actions do
    defaults [
      :read,
      :destroy,
      update: [:name, :date, :start_time, :end_time]
    ]

    create :create do
      accept [:name, :date, :start_time, :end_time]

      argument :location, :uuid do
        allow_nil? false
      end

      change manage_relationship(:location, :location,
               type: :append_and_remove,
               on_lookup: :relate,
               value_is_key: :id
             )
    end

    read :list_for_location_and_date do
      argument :location_id, :uuid do
        allow_nil? false
      end

      argument :date, :date do
        allow_nil? false
      end

      prepare build(filter: expr(location_id == ^arg(:location_id) and date == ^arg(:date)))
    end

    read :list_upcoming do
      argument :location_id, :uuid do
        allow_nil? false
      end

      argument :from_date, :date do
        allow_nil? false
      end

      prepare build(filter: expr(location_id == ^arg(:location_id) and date >= ^arg(:from_date)))
    end
  end

  preparations do
    prepare build(sort: [date: :asc, start_time: :asc])
  end

  # Dog shelters don't really get overnight volunteers, so this is a safe assumption for now.
  validations do
    validate compare(:end_time, greater_than: :start_time) do
      message "must be after the start time"
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :date, :date do
      allow_nil? false
      public? true
    end

    attribute :start_time, :time do
      allow_nil? false
      public? true
    end

    attribute :end_time, :time do
      allow_nil? false
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :location, Doggo.Shelter.Location do
      allow_nil? false
      attribute_public? true
    end
  end

  identities do
    identity :unique_scheduled_shift_time, [:location_id, :date, :start_time, :end_time, :name]
  end
end
