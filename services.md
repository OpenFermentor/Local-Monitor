# Service specifications for the Rest-API and WebSockets

## API
* base url: `localhost:4000/api`

### Routines
###### POST `/api/routines/stop`
Stops the currenlty running routine.
Response:
``` json
200 {}
```
###### POST `/api/routines/start`
Request:
```json
{
  "id": 10,
}
```
Response:
``` json
200 {
  "data": {
    "id": 10,
    "title": "title",
    "strain": "strain",
    "medium": "medium",
    "target_temp": "target_temp",
    "target_ph": "target_ph",
    "target_co2": "target_co2",
    "target_density": "target_density",
    "estimated_time_seconds": "estimated_time_seconds",
    "extra_notes": "extra_notes",
    "inserted_at": "inserted_at",
    "updated_at": "updated_at",  
  }
}

422 {"errors": []}
```
###### GET `/api/routines`
Response:
``` json
200 {
  "data": [{
    "id": 10,
    "title": "title",
    "strain": "strain",
    "medium": "medium",
    "target_temp": "target_temp",
    "target_ph": "target_ph",
    "target_co2": "target_co2",
    "target_density": "target_density",
    "estimated_time_seconds": "estimated_time_seconds",
    "extra_notes": "extra_notes",
    "inserted_at": "inserted_at",
    "updated_at": "updated_at",  
  }]
}

422 {"errors": []}
```
###### GET `/api/routines/:id`
###### POST `/api/routines`
Creates and starts a new routine.
It fails if there is a routine already started.
Response:
``` json
200 {
  "data": {
    "id": 10,
    "title": "title",
    "strain": "strain",
    "medium": "medium",
    "target_temp": "target_temp",
    "target_ph": "target_ph",
    "target_co2": "target_co2",
    "target_density": "target_density",
    "estimated_time_seconds": "estimated_time_seconds",
    "extra_notes": "extra_notes",
    "inserted_at": "inserted_at",
    "updated_at": "updated_at",  
  }
}

422 {"errors": []}
```
###### PUT `/api/routines/:id`
Updates a routine
Response:
``` json
200 {
  "data": {
    "id": 10,
    "title": "title",
    "strain": "strain",
    "medium": "medium",
    "target_temp": "target_temp",
    "target_ph": "target_ph",
    "target_co2": "target_co2",
    "target_density": "target_density",
    "estimated_time_seconds": "estimated_time_seconds",
    "extra_notes": "extra_notes",
    "inserted_at": "inserted_at",
    "updated_at": "updated_at",  
  }
}

422 {"errors": []}
```
###### DELETE `/api/routines/:id`
Deletes a routine
Response:
``` json
200 {}

500 {}
```

### Readings

###### GET `/api/routines/:routine_id/readings`
Response:
```json
200 {
  "data": [{
    "id": 10,
    "temp": "temp",
    "ph": "ph",
    "co2": "co2",
    "density": "density",
    "routine_id": "routine_id"
    }]
  }
```
###### GET `/api/routines/:routine_id/readings/:id`
Response:
```json
200 {
  "data": {
    "id": 10,
    "temp": "temp",
    "ph": "ph",
    "co2": "co2",
    "density": "density",
    "routine_id": "routine_id"
    }
  }
```
###### DELETE `/api/routines/:routine_id/readings/:id`
Response:
```json
200 {}

500 {}
```

## Socket
* Base url: `localhost:4000/socket`
* Topic: `routine`
* Events: `update | start | stop | alert`

#### Events

###### Start
Called when the routine starts
* Event: `start`
* Payload:
```json
  {"id": "routine.id", "target_temp": "routine.target_temp"}
```

###### Stop
Called when the routine stops
* Event: `stop`
* Payload:
```json
  {"id": "routine.id", "target_temp": "routine.target_temp"}
```

###### Update
Called when a new reading is recorded
* Event: `update`
* Payload:
```json
  {"id": "reading.id", "temp": "reading.temp"}
```

###### Alert
Called when an alert is issued after processing a reading
* Event: `start`
* Payload:
```json
  {"message": "message", "errors": ["error1", "errorN"]}
```