defmodule DemoWeb.DummyLive do
  use DemoWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Dummy Live
      <:actions>
        <.link patch={~p"/"}>
          <.button>Home</.button>
        </.link>
      </:actions>
    </.header>

    <.button phx-click="event">Dummy button</.button>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, :page_title, "Dummy Live")}
  end

  @impl true
  def handle_event("event", _params, socket) do
    Process.sleep(1000)
    {:noreply, socket}
  end
end
