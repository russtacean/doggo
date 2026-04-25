defmodule Doggo.Shelter.Location do
  use Ash.Resource, otp_app: :doggo, domain: Doggo.Shelter, data_layer: AshPostgres.DataLayer

  postgres do
    table "locations"
    repo Doggo.Repo

    custom_indexes do
      index [:archived]
    end
  end

  actions do
    defaults [
      :read,
      :destroy,
      create: [:name, :address, :city, :region, :postal_code, :country, :timezone],
      update: [:name, :address, :city, :region, :postal_code, :country, :timezone, :archived]
    ]

    read :list_active do
      prepare build(filter: [archived: false])
    end
  end

  preparations do
    prepare build(sort: [name: :asc])
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :address, :string do
      public? true
    end

    attribute :city, :string do
      public? true
    end

    attribute :region, :string do
      public? true
    end

    attribute :postal_code, :string do
      public? true
    end

    attribute :country, :string do
      allow_nil? false
      public? true
      default "USA"
    end

    attribute :timezone, :string do
      allow_nil? false
      public? true
      default "America/New_York"
    end

    attribute :archived, :boolean do
      allow_nil? false
      public? true
      default false
    end

    timestamps()
  end

  relationships do
    has_many :enclosures, Doggo.Shelter.Enclosure
    has_many :scheduled_shifts, Doggo.Shelter.ScheduledShift
    has_many :recurring_shifts, Doggo.Shelter.RecurringShift
  end

  calculations do
    calculate :formatted_address, :string, Doggo.Shelter.Location.FormattedAddress
  end

  aggregates do
    count :enclosure_count, :enclosures

    count :available_enclosure_count, :enclosures do
      filter expr(status == :available)
    end
  end
end
