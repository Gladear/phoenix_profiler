defmodule DemoWeb.ConferenceHTML do
  use DemoWeb, :html

  embed_templates "conference_html/*"

  @doc """
  Renders a conference form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def conference_form(assigns)
end
