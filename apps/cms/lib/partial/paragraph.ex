defmodule CMS.Partial.Paragraph do
  @moduledoc """

  This module represents the suite of paragraph types that we support on Drupal.
  To add a new Drupal paragraph type, say MyPara, that should show up on pages
  via Phoenix, make the following changes:

  * Pull the most recent content from the CMS. Locally, update the
    /cms/style-guide/paragraphs page, which demonstrates all our paragraphs,
    to include this new paragraph.
  * Load /cms/style-guide/paragraphs?_format=json from the CMS and update
    /cms/style-guide/paragraphs.json.
  * Create a new module, CMS.Partial.Paragraph.MyPara in lib/paragraph/my_para.ex.
  * Create a _my_para.html.eex partial (filename pattern must match module name)
  * Add that type to CMS.Partial.Paragraph.t here.
  * Update this module's from_api/1 function to dispatch to the MyPara.from_api
  * Update CMS.ParagraphTest to ensure it is parsed correctly
  * Update Site.ContentViewTest to ensure it is rendered correctly
  * After the code is merged and deployed, update /cms/style-guide/paragraphs
    on the live CMS
  """

  alias CMS.Partial.Paragraph.{
    Accordion,
    AccordionSection,
    Callout,
    Column,
    ColumnMulti,
    ColumnMultiHeader,
    ContentList,
    CustomHTML,
    Description,
    DescriptionList,
    DescriptiveLink,
    FareCard,
    FilesGrid,
    PeopleGrid,
    PhotoGallery,
    TitleCardSet,
    Unknown
  }

  @types [
    Accordion,
    AccordionSection,
    Callout,
    Column,
    ColumnMulti,
    ColumnMultiHeader,
    ContentList,
    CustomHTML,
    Description,
    DescriptionList,
    DescriptiveLink,
    FareCard,
    FilesGrid,
    PeopleGrid,
    PhotoGallery,
    TitleCardSet,
    Unknown
  ]

  @type t ::
          Accordion.t()
          | AccordionSection.t()
          | Callout.t()
          | Column.t()
          | ColumnMulti.t()
          | ColumnMultiHeader.t()
          | ContentList.t()
          | CustomHTML.t()
          | Description.t()
          | DescriptionList.t()
          | DescriptiveLink.t()
          | FareCard.t()
          | FilesGrid.t()
          | PeopleGrid.t()
          | PhotoGallery.t()
          | TitleCardSet.t()
          | Unknown.t()

  @type name ::
          Accordion
          | AccordionSection
          | Callout
          | Column
          | ColumnMulti
          | ColumnMultiHeader
          | ContentList
          | CustomHTML
          | Description
          | DescriptionList
          | DescriptiveLink
          | FareCard
          | FilesGrid
          | PeopleGrid
          | PhotoGallery
          | TitleCardSet
          | Unknown

  @spec from_api(map, map) :: t
  def from_api(data, query_params \\ %{})

  def from_api(%{"type" => [%{"target_id" => "entity_reference"}]} = para, _query_params) do
    Callout.from_api(para)
  end

  def from_api(%{"type" => [%{"target_id" => "multi_column_header"}]} = para, _query_params) do
    ColumnMultiHeader.from_api(para)
  end

  def from_api(%{"type" => [%{"target_id" => "multi_column"}]} = para, query_params) do
    ColumnMulti.from_api(para, query_params)
  end

  def from_api(%{"type" => [%{"target_id" => "column"}]} = para, query_params) do
    Column.from_api(para, query_params)
  end

  def from_api(%{"type" => [%{"target_id" => "content_list"}]} = para, query_params) do
    ContentList.from_api(para, query_params)
  end

  def from_api(%{"type" => [%{"target_id" => "custom_html"}]} = para, _query_params) do
    CustomHTML.from_api(para)
  end

  def from_api(%{"type" => [%{"target_id" => "definition"}]} = para, _query_params) do
    Description.from_api(para)
  end

  def from_api(%{"type" => [%{"target_id" => "description_list"}]} = para, query_params) do
    DescriptionList.from_api(para, query_params)
  end

  def from_api(%{"type" => [%{"target_id" => "fare_card"}]} = para, query_params) do
    FareCard.from_api(para, query_params)
  end

  def from_api(%{"type" => [%{"target_id" => "files_grid"}]} = para, _query_params) do
    FilesGrid.from_api(para)
  end

  def from_api(%{"type" => [%{"target_id" => "people_grid"}]} = para, _query_params) do
    PeopleGrid.from_api(para)
  end

  def from_api(%{"type" => [%{"target_id" => "photo_gallery"}]} = para, _query_params) do
    PhotoGallery.from_api(para)
  end

  def from_api(%{"type" => [%{"target_id" => "tabs"}]} = para, query_params) do
    Accordion.from_api(para, query_params)
  end

  def from_api(%{"type" => [%{"target_id" => "tab"}]} = para, query_params) do
    AccordionSection.from_api(para, query_params)
  end

  def from_api(%{"type" => [%{"target_id" => "title_card"}]} = para, _query_params) do
    DescriptiveLink.from_api(para)
  end

  def from_api(%{"type" => [%{"target_id" => "title_card_set"}]} = para, _query_params) do
    TitleCardSet.from_api(para)
  end

  @doc "This ¶ type has a single paragraph reference within. Get the nested paragraph."
  def from_api(%{"type" => [%{"target_id" => "from_library"}]} = para, query_params) do
    parse_library_item(para, query_params)
  end

  @doc "For directly accessing a reusable paragraph (from paragraphs API endpoint)"
  def from_api(%{"paragraphs" => [para]}, query_params) do
    from_api(para, query_params)
  end

  def from_api(unknown_paragraph_type, _query_params) do
    Unknown.from_api(unknown_paragraph_type)
  end

  @spec right_rail?(t) :: boolean
  def right_rail?(%{right_rail: true}), do: true
  def right_rail?(_), do: false

  @spec full_bleed?(t) :: boolean
  def full_bleed?(%Callout{}), do: true
  def full_bleed?(%{right_rail: true}), do: true
  def full_bleed?(_), do: false

  @spec get_types() :: [name]
  def get_types, do: @types

  # Pass through the nested paragraph and host ID
  @spec parse_library_item(map, map) :: t
  defp parse_library_item(data, query_params) do
    data
    |> Map.get("field_reusable_paragraph")
    |> List.first()
    |> Map.get("paragraphs")
    |> List.first()
    |> Map.put("parent_id", Map.get(data, "parent_id"))
    |> from_api(query_params)
  end
end
