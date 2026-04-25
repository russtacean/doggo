defmodule Doggo.AshAssertions do
  @moduledoc """
  Shared assertion helpers for Ash-related tests.
  """

  import ExUnit.Assertions

  def assert_required_error(errors, field) do
    assert Enum.any?(errors, fn
             %Ash.Error.Changes.Required{field: ^field} -> true
             _error -> false
           end)
  end

  def assert_invalid_attribute_error(errors, field, message_part \\ nil) do
    assert Enum.any?(errors, fn
             %Ash.Error.Changes.InvalidAttribute{field: ^field, message: message} ->
               is_nil(message_part) or String.contains?(message, message_part)

             _error ->
               false
           end)
  end

  def assert_invalid_relationship_error(errors, relationship) do
    assert Enum.any?(errors, fn
             %Ash.Error.Changes.InvalidRelationship{relationship: ^relationship} -> true
             %Ash.Error.Query.NotFound{path: [^relationship]} -> true
             _error -> false
           end)
  end
end
