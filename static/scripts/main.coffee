Dom = React.DOM

Index = React.createClass
    displayName: "Index"

    render: ->
        (Dom.p null, "Hello from Index!")

About = React.createClass
    displayName: "About"

    render: ->
        (Dom.p null, "Hello from About!")

routes =
    "/": Index()
    "/about": About()

navItems =
    "Index": "/"
    "About": "/about"

Root = React.createClass
    displayName: "Root"

    getInitialState: ->
        currentComponent: Index()

    componentDidMount: ->
        routes = _.clone routes
        _.forEach routes, (component, url) =>
            routes[url] = =>
                @setState currentComponent: component

        router = Router routes
        router.init @props.defaultRoute

    render: ->
        (Dom.div null,
            (ReactBootstrap.Nav bsStyle: "pills",
                _.map @props.navItems, (url, title) ->
                    (ReactBootstrap.NavItem href: "##{ url }", title))
            (@state.currentComponent))

mountNode = document.getElementsByClassName("container")[0]
React.renderComponent Root(navItems: navItems, defaultRoute: "/"), mountNode
