{render,factory, div} = require "../react-utils"
Editor = require "./editor"
Arena = require "./arena"
App = require "./app"
Leaderboard = require "./leaderboard"
PatternDetail = require "./pattern-detail"
ready = require "document-ready"
{Router, Route, browserHistory} = require "react-router"
React = require "react"
{createFactory, createElement} = require "react"
#Router =createFactory Router
#Route = createFactory Route
ready ->
  routes= [
    path:"/"
    component:App
    indexRoute: onEnter: (nextState, replace) => replace '/editor'
    childRoutes: [
      path:"editor"
      component: Editor
    ,
      path:"patterns/:spec"
      component: PatternDetail
    ,
      path:"kiosk/arena"
      component: Arena
    ,
      path:"kiosk/leaderboard"
      component: Leaderboard
    ]
  ]
  render(
    createElement Router,
      history:browserHistory
      routes: routes
    document.getElementById "app-root"
  )
