local Buffer = {};

function Buffer.newMotorToBuffer(motor: Motor6D, useTransformC0)
    local newBuffer = buffer.create(12);

    local c0X, c0Y, c0Z = (useTransformC0 and motor.Transform or motor.C0):ToOrientation();
    local c1X, c1Y, c1Z = motor.C1:ToOrientation();

    buffer.writei16(newBuffer, 0, math.round(c0X*100))
    buffer.writei16(newBuffer, 2, math.round(c0Y*100))
    buffer.writei16(newBuffer, 4, math.round(c0Z*100))

    buffer.writei16(newBuffer, 6, math.round(c1X*100))
    buffer.writei16(newBuffer, 8, math.round(c1Y*100))
    buffer.writei16(newBuffer, 10, math.round(c1Z*100))

    return newBuffer;
end

function Buffer.readMotorBuffer(b: buffer)
    return {
        C0 = CFrame.Angles(
            buffer.readi16(b, 0)/100,
            buffer.readi16(b, 2)/100,
            buffer.readi16(b, 4)/100
        );
        C1 = CFrame.Angles(
            buffer.readi16(b, 6)/100,
            buffer.readi16(b, 8)/100,
            buffer.readi16(b, 10)/100
        );
    }
end

return Buffer;