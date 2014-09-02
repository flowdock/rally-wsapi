# rally-wsapi

Rally WSAPI client written in Ruby.

## Usage

In order to authenticate to WSAPI, you will need to obtain an API key for the Rally account. This can be done via [Rally OAuth](https://github.com/RallySoftware/rally-oauth-examples), for example.

Once you have the API key, you can initialize the session object with the key:
```
s = Wsapi::Session.new("deadbeefdeadbeef")
```

The constructor also accepts the following options:
  * `:workspace_id`, if not given, user's default workspace is used for queries
  * `:version`, WSAPI version, default is `3.0`


## Method reference

Some methods accept an optional hash that can have the following options:
 * `:query`, add conditions for fetching objects. E.g. `(UserName = "John")`, see WSAPI documentation for details about the syntax.
 * `:start`, default: `1`, fetch results starting from given number
 * `:workspace`, override workspace setting of the session
 * `:pagesize`, default: `200`, page size for results
 * `:fetch`, default: `true`, fetch full objects

### Get the authenticated user
```
get_current_user
```

### Get a user
```
get_user(user_id)
```

### Get a user by username
```
get_user_by_username(username)
```

### Get the subscription of the authenticated user
```
get_user_subscription
```

### Get a subscription
```
get_project(subscription_id)
```

### Get a project
```
get_project(project_id)
```

### Get projecsts of the authenticated user
```
get_projects(opts = {})
```

### Get team members in a project
```
get_team_members(project_id, opts = {})
```

### Get editors in a project
```
get_editors(project_id, opts = {})
```
