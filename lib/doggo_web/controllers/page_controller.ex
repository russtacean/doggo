defmodule DoggoWeb.PageController do
  use DoggoWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
