-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

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

assignment = rima.new()

assignment.meet_demand[{s=stores}] = rima.C(rima.sum{p=plants}(flow[p][s]), "==", s.demand)
assignment.respect_capacity[{p=plants}] = rima.C(rima.sum{s=stores}(flow[p][s]), "<=", p.capacity)
assignment.flow[{p=plants}][{s=stores}] = rima.positive()
assignment.total_transport_cost = rima.sum{p=plants, s=store_order}(flow[p][s] * transport_cost[p][s])
--assignment.objective = total_transport_cost
assignment.sense = "minimise"

rima.mp.write(assignment)
--[[
Minimise:
  sum{p in plants, s in store_order}(flow[p, s]*transport_cost[p, s])
Subject to:
  meet_demand:      sum{p in plants}(flow[p, s]) == s.demand for all {s in stores}
  respect_capacity: sum{s in stores}(flow[p, s]) <= p.capacity for all {p in plants}
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

shopping = rima.instance(assignment, { objective=total_transport_cost}, shopping_data)
rima.mp.write(shopping)
--[[
Minimise:
  8*flow.Denver.Barstow + 5*flow.Denver.Dallas + ...
Subject to:
  meet_demand.Tucson:                 flow.Denver.Tucson + flow.Phoenix.Tucson + flow['Los Angeles'].Tucson + flow['San Franscisco'].Tucson == 1500
  meet_demand.Dallas:                 flow.Denver.Dallas + flow.Phoenix.Dallas + flow['Los Angeles'].Dallas + flow['San Franscisco'].Dallas == 1200
  meet_demand['San Diego']:           flow.Denver['San Diego'] + flow.Phoenix['San Diego'] + flow['Los Angeles', 'San Diego'] + flow['San Franscisco', 'San Diego'] == 1700
  meet_demand.Barstow:                flow.Denver.Barstow + flow.Phoenix.Barstow + flow['Los Angeles'].Barstow + flow['San Franscisco'].Barstow == 1000
  respect_capacity.Phoenix:           flow.Phoenix.Barstow + flow.Phoenix.Dallas + flow.Phoenix.Tucson + flow.Phoenix['San Diego'] <= 1700
  respect_capacity['Los Angeles']:    flow['Los Angeles', 'San Diego'] + flow['Los Angeles'].Barstow + flow['Los Angeles'].Dallas + flow['Los Angeles'].Tucson <= 2000
  respect_capacity['San Franscisco']: flow['San Franscisco', 'San Diego'] + flow['San Franscisco'].Barstow + flow['San Franscisco'].Dallas + flow['San Franscisco'].Tucson <= 1700
  respect_capacity.Denver:            flow.Denver.Barstow + flow.Denver.Dallas + flow.Denver.Tucson + flow.Denver['San Diego'] <= 2000
--]]

objective, r = rima.mp.solve("lpsolve", shopping)
for pn, p in pairs(r.flow) do
  for sn, s in pairs(p) do
    io.write(("%s -> %s : %g\n"):format(pn, sn, s.p))
  end
end


-- Facility Location -----------------------------------------------------------

build_cost = rima.R"build_cost"

facility_location = rima.instance(assignment)

facility_location.build_plants[{p=plants}] = rima.C(rima.sum{s=store_order}(flow[p][s]), "<=", p.capacity * p.built)
facility_location.build_cost = rima.sum{p=plants}(p.build_cost * p.built)
facility_location.plants[{p=plants}].built = rima.binary()
facility_location.objective = total_transport_cost + build_cost

rima.mp.write(facility_location)
--[[
Minimise:
  sum{p in plants, s in store_order}(flow[p, s]*transport_cost[p, s]) + sum{p in plants}(p.build_cost*p.built)
Subject to:
  respect_capacity[p in plants]: sum{s in stores}(flow[p, s]) <= p.capacity
  build_plants[p in plants]:     sum{s in store_order}(flow[p, s]) <= p.built*p.capacity
  meet_demand[s in stores]:      sum{p in plants}(flow[p, s]) == s.demand
--]]

build_shops = rima.instance(facility_location, shopping_data,
{
  plants =
  {
    ["San Franscisco"]    = { build_cost = 70000 },
    ["Los Angeles"]       = { build_cost = 70000 },
    Phoenix               = { build_cost = 65000 },
    Denver                = { build_cost = 70000 },
  },
})

objective, r = rima.mp.solve("cbc", build_shops)
io.write(("Cost: $%.2f\n"):format(objective))
for pn, p in pairs(r.plants) do
  io.write(("%s : %g\n"):format(pn, p.built.p))
end
for pn, p in pairs(r.flow) do
  for sn, s in pairs(p) do
    io.write(("%s -> %s : %g\n"):format(pn, sn, s.p))
  end
end


-- EOF -------------------------------------------------------------------------
