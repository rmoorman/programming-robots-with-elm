module Control exposing (Control, followLine, grab, idle, isIdle, moveBy, output, release, update)

import LightCalibration
import Lights
import Perception exposing (Perception)
import Robot exposing (Input, Output)


type Control
    = Idle
    | Grab Timer
    | Release Timer
    | FollowLine
    | MoveTo { left : Int, right : Int }
    | MoveBy { leftDelta : Int, rightDelta : Int }


type Timer
    = Starting
    | Since Int



-- CONSTRUCTORS


idle : Control
idle =
    Idle


grab : Control
grab =
    Grab Starting


release : Control
release =
    Release Starting


followLine : Control
followLine =
    FollowLine


moveBy : { leftDelta : Int, rightDelta : Int } -> Control
moveBy params =
    MoveBy params



-- INSPECTION


isIdle : Control -> Bool
isIdle control =
    case control of
        Idle ->
            True

        _ ->
            False



-- UPDATE AND OUTPUTS


grabDuration : Int
grabDuration =
    2000


releaseDuration : Int
releaseDuration =
    2000


update : Perception -> Control -> Control
update perception control =
    case control of
        Idle ->
            control

        Grab Starting ->
            Grab (Since perception.time)

        Grab (Since startTime) ->
            if perception.time - startTime > grabDuration then
                Idle

            else
                control

        Release Starting ->
            Release (Since perception.time)

        Release (Since startTime) ->
            if perception.time - startTime > releaseDuration then
                Idle

            else
                control

        FollowLine ->
            control

        MoveBy { leftDelta, rightDelta } ->
            MoveTo
                { left = perception.wheels.left + leftDelta
                , right = perception.wheels.right + rightDelta
                }

        MoveTo { left, right } ->
            if within 5 left perception.wheels.left && within 5 right perception.wheels.right then
                Idle

            else
                control


output : Control -> Perception -> Output
output control perception =
    case control of
        Idle ->
            { leftMotor = 0.0
            , rightMotor = 0.0
            , clawMotor = 0.0
            , lights = Nothing
            }

        Grab _ ->
            { leftMotor = 0.0
            , rightMotor = 0.0
            , clawMotor = -1.0
            , lights = Nothing
            }

        Release _ ->
            { leftMotor = 0.0
            , rightMotor = 0.0
            , clawMotor = 1.0
            , lights = Nothing
            }

        FollowLine ->
            { leftMotor = perception.lightSensor
            , rightMotor = 1.0 - perception.lightSensor
            , clawMotor = 0.0
            , lights = Nothing
            }

        MoveTo { left, right } ->
            { leftMotor = speed (left - perception.wheels.left)
            , rightMotor = speed (right - perception.wheels.right)
            , clawMotor = 0.0
            , lights = Nothing
            }

        MoveBy _ ->
            output Idle perception



-- HELPERS


speed : Int -> Float
speed delta =
    delta
        |> toFloat
        |> (*) 0.01
        |> max -1.0
        |> min 1.0


within : Int -> Int -> Int -> Bool
within tolerance a b =
    abs (a - b) < tolerance


error : Output
error =
    { leftMotor = 0.0
    , rightMotor = 0.0
    , clawMotor = 0.0
    , lights = Just { left = Lights.red, right = Lights.red }
    }
