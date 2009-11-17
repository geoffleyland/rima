-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

require("rima")

-- Assignment ------------------------------------------------------------------

--[[
This is the Rima version of PuLP's
http://code.google.com/p/pulp-or/wiki/AFacilityLocationProblem
Extending an assignment problem to a facility location problem was suggested by
Leo Lopes
--]]

p, plants = rima.R"p, plants"
s, stores, store_order = rima.R"s, stores, store_order"
flow, transport_cost, total_transport_cost = rima.R"flow, transport_cost, total_transport_cost"

assignment = rima.formulation:new()

assignment:add({s=stores}, rima.sum{p=plants}(flow[p][s]), "==", s.demand)
assignment:add({p=plants}, rima.sum{s=stores}(flow[p][s]), "<=", p.capacity)
assignment:scope().flow[{p=plants}][{s=stores}] = rima.positive()
assignment:scope().total_transport_cost = rima.sum{p=plants, s=store_order}(flow[p][s] * transport_cost[p][s])
assignment:set_objective(total_transport_cost, "minimise")

assignment:write()
--[[
Minimise:
  sum{p in plants, s in store_order}(flow[p, s]*transport_cost[p, s])
Subject to:
  sum{p in plants}(flow[p, s]) == s.demand for all {s in stores}
  sum{s in stores}(flow[p, s]) <= p.capacity for all {p in plants}
--]]

shopping_data =
{
  plants =
  {
    ["San Franscisco"]    = { capacity = 1700 },
    ["Los Angeles"]       = { capacity = 2000 },
    Phoenix               = { capacity = 1700 },
    Denver                = { capacity = 2000 },
  },

  store_order = { "San Diego", "Barstow", "Tucson", "Dallas" },
  stores =
  {
    ["San Diego"]         = { demand = 1700 },
    Barstow               = { demand = 1000 },
    Tucson                = { demand = 1500 },
    Dallas                = { demand = 1200 },
  },

  transport_cost =
  {
                          --  SD BA TU DA
    ["San Franscisco"]    = { 5, 3, 2, 6 },
    ["Los Angeles"]       = { 4, 7, 8, 10 },
    Phoenix               = { 6, 5, 3, 8 },
    Denver                = { 9, 8, 6, 5 },
  },
}

shopping = assignment:instance(shopping_data)
shopping:write()
--[[
Minimise:
  8*flow.Denver.Barstow + 5*flow.Denver.Dallas + ...
Subject to:
  flow.Denver.Tucson + flow.Phoenix.Tucson + flow['Los Angeles'].Tucson + flow['San Franscisco'].Tucson == 1500
  flow.Denver.Dallas + flow.Phoenix.Dallas + flow['Los Angeles'].Dallas + flow['San Franscisco'].Dallas == 1200
  flow.Denver['San Diego'] + flow.Phoenix['San Diego'] + flow['Los Angeles', 'San Diego'] + flow['San Franscisco', 'San Diego'] == 1700
  flow.Denver.Barstow + flow.Phoenix.Barstow + flow['Los Angeles'].Barstow + flow['San Franscisco'].Barstow == 1000
  flow.Phoenix.Barstow + flow.Phoenix.Dallas + flow.Phoenix.Tucson + flow.Phoenix['San Diego'] <= 1700
  flow['Los Angeles', 'San Diego'] + flow['Los Angeles'].Barstow + flow['Los Angeles'].Dallas + flow['Los Angeles'].Tucson <= 2000
  flow['San Franscisco', 'San Diego'] + flow['San Franscisco'].Barstow + flow['San Franscisco'].Dallas + flow['San Franscisco'].Tucson <= 1700
  flow.Denver.Barstow + flow.Denver.Dallas + flow.Denver.Tucson + flow.Denver['San Diego'] <= 2000
--]]

r = shopping:solve("lpsolve")
for pn, p in pairs(r.variables.flow) do
  for sn, s in pairs(p) do
    io.write(("%s -> %s : %g\n"):format(pn, sn, s.p))
  end
end


-- Facility Location -----------------------------------------------------------

build_cost = rima.R"build_cost"

facility_location = assignment:instance()

facility_location:add({p=plants}, rima.sum{s=store_order}(flow[p][s]), "<=", p.capacity * p.built)
facility_location:scope().build_cost = rima.sum{p=plants}(p.build_cost * p.built)
facility_location:scope().plants[{p=plants}].built = rima.binary()
facility_location:set_objective(total_transport_cost + build_cost, "minimise")

facility_location:write()
--[[
Minimise:
  sum{p in plants, s in store_order}(flow[p, s]*transport_cost[p, s]) + sum{p in plants}(p.build_cost*p.built)
Subject to:
  sum{p in plants}(flow[p, s]) == s.demand for all {s in stores}
  sum{s in stores}(flow[p, s]) <= p.capacity for all {p in plants}
  sum{s in store_order}(flow[p, s]) <= p.built*p.capacity for all {p in plants}
--]]

build_shops_1 = facility_location:instance(shopping_data)
build_shops_2 = build_shops_1:instance{
  plants =
  {
    ["San Franscisco"]    = { build_cost = 70000 },
    ["Los Angeles"]       = { build_cost = 70000 },
    Phoenix               = { build_cost = 65000 },
    Denver                = { build_cost = 70000 },
  },
}

r = build_shops_2:solve("cbc")
io.write(("Cost: $%.2f\n"):format(r.objective))
for pn, p in pairs(r.variables.plants) do
  io.write(("%s : %g\n"):format(pn, p.built.p))
end
for pn, p in pairs(r.variables.flow) do
  for sn, s in pairs(p) do
    io.write(("%s -> %s : %g\n"):format(pn, sn, s.p))
  end
end

-- EOF -------------------------------------------------------------------------