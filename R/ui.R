source('global.R', local = T)

###8. UI ----
ui <- dashboardPage(skin = "blue",
                    header,
                    dashboard,
                    body
)