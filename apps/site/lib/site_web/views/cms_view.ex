defmodule SiteWeb.CMSView do
  @moduledoc """
  Handles rendering of partial content from the CMS.
  """
  use SiteWeb, :view

  import SiteWeb.CMS.PageView, only: [render_page: 2]
  import SiteWeb.CMS.ParagraphView, only: [render_paragraph: 2]

  alias CMS.Field.File
  alias CMS.Partial.Paragraph

  defdelegate fa_icon_for_file_type(mime), to: Site.FontAwesomeHelpers

  def file_description(%File{description: desc}) when not is_nil(desc) and desc != "" do
    desc
  end

  def file_description(%File{url: url}) do
    url |> Path.basename() |> URI.decode()
  end

  @doc "Nicely renders the duration of an event, given two DateTimes."
  @spec render_duration(NaiveDateTime.t() | DateTime.t(), NaiveDateTime.t() | DateTime.t() | nil) ::
          String.t()
  def render_duration(start_time, end_time)

  def render_duration(start_time, nil) do
    start_time
    |> maybe_shift_timezone
    |> do_render_duration(nil)
  end

  def render_duration(start_time, end_time) do
    start_time
    |> maybe_shift_timezone
    |> do_render_duration(maybe_shift_timezone(end_time))
  end

  def maybe_shift_timezone(%NaiveDateTime{} = time) do
    time
  end

  def maybe_shift_timezone(%DateTime{} = time) do
    Util.to_local_time(time)
  end

  defp do_render_duration(start_time, nil) do
    "#{format_date(start_time)} at #{format_time(start_time)}"
  end

  defp do_render_duration(
         %{year: year, month: month, day: day} = start_time,
         %{year: year, month: month, day: day} = end_time
       ) do
    "#{format_date(start_time)} at #{format_time(start_time)} - #{format_time(end_time)}"
  end

  defp do_render_duration(start_time, end_time) do
    "#{format_date(start_time)} #{format_time(start_time)} - #{format_date(end_time)} #{
      format_time(end_time)
    }"
  end
end
