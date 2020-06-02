Config = {
  enabled = true,
  runEvery = 2, -- in seconds. Anywhere between (2-10) is good.
  populateOnReboot = true, -- populate server vehicles after server reboot
  debug = false, -- show updates in the console
  db = {
    table = 'owned_vehicles', -- name of player owned vehicles database table
    col = 'vehicle', -- name of vehicle properties column
  },
}