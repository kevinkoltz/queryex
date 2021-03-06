defmodule Integration.Query.Test do
  use QueryEx.ModelCase

  import QueryEx.Factory

  test "simple request" do
    person = insert(:person)

    result =
      Dummy.Person
      |> QueryEx.from_query()
      |> QueryEx.build()
      |> Dummy.Repo.one()
      |> elem(0)

    assert result.id == person.id
  end

  test "simple filter" do
    person = insert(:person)
    insert(:person)

    result =
      Dummy.Person
      |> QueryEx.from_query()
      |> QueryEx.filter("email", :=, person.email)
      |> QueryEx.build()
      |> Dummy.Repo.one()
      |> elem(0)

    assert result.id == person.id
  end

  test "complex filter" do
    insert(:person)
    person = insert(:person, organization: insert(:organization, name: "Test"))

    result =
      Dummy.Person
      |> QueryEx.from_query()
      |> QueryEx.filter("organization.name", :=, "Test")
      |> QueryEx.build()
      |> Dummy.Repo.one()
      |> elem(0)

    assert result.id == person.id
  end

  test "kitchen sink" do
    organization = insert(:organization)
    person1 = insert(:person, email: "a", organization: organization)
    person2 = insert(:person, email: "b", organization: organization)
    insert(:person)

    # Setup a base query that filters by organization name
    query =
      from(
        p in Dummy.Person,
        join: o in Dummy.Organization,
        where: o.id == p.organization_id,
        where: o.name == ^organization.name
      )

    result =
      query
      |> QueryEx.from_query()
      |> QueryEx.order_by("email", :desc)
      |> QueryEx.order_by("organization.name", :asc)
      |> QueryEx.side_load("organization")
      |> QueryEx.build()
      |> Dummy.Repo.all()
      |> Enum.map(&elem(&1, 0))

    assert [person2.id, person1.id] == Enum.map(result, & &1.id)
    assert [organization.name, organization.name] == Enum.map(result, & &1.organization.name)
  end
end
