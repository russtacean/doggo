defmodule Doggo.Shelter.Enclosure do
  use Ash.Resource, otp_app: :doggo, domain: Doggo.Shelter, data_layer: AshPostgres.DataLayer

  postgres do
    table "enclosures"
    repo Doggo.Repo

    references do
      reference :location, index?: true, on_delete: :delete
    end

    custom_indexes do
      index [:location_id, :status]
    end
  end

  actions do
    defaults [:read, :destroy, update: [:name, :status]]

    create :create do
      accept [:name, :status]

      argument :location, :uuid do
        allow_nil? false
      end

      change manage_relationship(:location, :location,
               type: :append_and_remove,
               on_lookup: :relate,
               value_is_key: :id
             )
    end

    read :list_for_location do
      argument :location_id, :uuid do
        allow_nil? false
      end

      prepare build(filter: expr(location_id == ^arg(:location_id)))
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

    attribute :status, :enclosure_status do
      public? true
      default :available
      allow_nil? false
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
