import "input" for Keyboard, Mouse, GamePad
import "graphics" for Canvas, Color, ImageData, Point
import "audio" for AudioEngine
import "random" for Random
import "dome" for Process, Window

class Game {
  static init() {
    Window.title = "Snake"
    __state = MainGame
    __state.init()
  }

  static update() {
    __x = Mouse.x
    __y = Mouse.y

    __state.update()
    if (__state.next) {
      __state = __state.next
      __state.init()
    }
    Mouse.hidden = Mouse.isButtonPressed("right")
  }

  static draw(dt) {
    __state.draw(dt)
    if (Mouse.isButtonPressed("right")) {
      Canvas.pset(__x, __y, Color.orange)
    }
  }
}

class MainGame {
  static next { __next}

  static init() {
    __next = null
    __w = 5
    __h = 5
    __x = 0
    __y = -1

    __snake = Snake.new()
    __fruit = Fruit.new()

    __score = 0

    Canvas.resize(320, 240)
  }

  static update() {
    var gamepad = GamePad.next
    if (Keyboard.isKeyDown("u")) {
      AudioEngine.unload("music")
    }
    if (Keyboard.isKeyDown("l")) {
      Window.lockstep = true
    }
    if (Keyboard.isKeyDown("v")) {
      Window.vsync = false
    }
    if (!__resized && Keyboard.isKeyDown("c")) {
      __resized = true
      if (Canvas.width != 64) {
        Canvas.resize(64, 64)
        Window.resize(64 * 2, 64 * 2)
      } else {
        Canvas.resize(320, 240)
        Window.resize(320 * 2, 240 * 2)
      }
    } else if (!Keyboard.isKeyDown("c")) {
      __resized = false

    }

    if (__x == 0 && Keyboard.isKeyDown("left") || gamepad.isButtonPressed("left") || gamepad.getAnalogStick("left").x < -0.25) {
      __x = -1
      __y = 0
    }
    if (__x == 0 && Keyboard.isKeyDown("right") || gamepad.isButtonPressed("right") || gamepad.getAnalogStick("left").x > 0.25) {
      __x = 1
      __y = 0
    }
    if (__y == 0 && Keyboard.isKeyDown("up") || gamepad.isButtonPressed("up") || gamepad.getAnalogStick("left").y < -0.25) {
      __x = 0
      __y = -1
    }
    if (__y == 0 && Keyboard.isKeyDown("down") || gamepad.isButtonPressed("down") || gamepad.getAnalogStick("left").y > 0.25) {
      __x = 0
      __y = 1
    }
    if (Keyboard.isKeyDown("escape") || gamepad.isButtonPressed("guide")) {
      Process.exit()
    }

    if (colliding(__snake.body[0], __fruit)) {
        __fruit = Fruit.new()
        __snake.addSegment()
        __score = __score + 1
    } 

    for (i in 0...(__snake.xhistory.count - 1)) {
      if (__snake.x == __snake.xhistory[i] && __snake.y == __snake.yhistory[i]) {
        __next = GameOverState
      }
    }

    __snake.move(__x, __y)
  }

  static colliding(o1, o2) {
    var box1 = Box.new(o1.x, o1.y, o1.x + o1.w, o1.y+o1.h)
    var box2 = Box.new(o2.x, o2.y, o2.x + o2.w, o2.y+o2.h)
    return box1.x1 < box2.x2 &&
      box1.x2 > box2.x1 &&
      box1.y1 < box2.y2 &&
      box1.y2 > box2.y1
  }

  static draw(dt) {
    Canvas.cls()
    Canvas.rectfill(0, 0, Canvas.width, 10, Color.black)
    Canvas.print("Score: %(__score)", 3, 3, Color.white)
    
    __snake.draw()
    __fruit.draw()
  }
}

class Box {
  construct new(x1, y1, x2, y2) {
    _p1 = Point.new(x1, y1)
    _p2 = Point.new(x2, y2)
  }

  x1 { _p1.x }
  y1 { _p1.y }
  x2 { _p2.x }
  y2 { _p2.y }
}

class Snake {
  construct new() {
    _x = Canvas.width / 2
    _y = Canvas.height - 20
    _xhistory = [_x]
    _yhistory = [_y]
    _head = Segment.new(_xhistory, _yhistory, 0)
    _body = [ _head ]
  }

  move(x, y) {
    _x = mod(_x + x, Canvas.width)
    _y = mod(_y + y, Canvas.height)
    _xhistory.add(_x)
    _yhistory.add(_y)

    if (_xhistory.count > (_body.count * _head.w) && _yhistory.count > (_body.count * _head.h)) {
      _xhistory.removeAt(0)
      _yhistory.removeAt(0)
    }

    for (i in 0..._body.count) {
        _body[i].update()
    }
  }

  mod(n, m) {
    return ((n % m) + m) % m
  }

  addSegment() {
    _body.add(Segment.new(_xhistory, _yhistory, _body.count))
  }

  draw() {
    for (i in 0..._body.count) {
        _body[i].draw()
    }
  }

  x { _x }
  y { _y }
  xhistory { _xhistory}
  yhistory { _yhistory}
  body { _body }
}

class Segment {
  construct new(xhistory, yhistory, position) {
    _w = 5
    _h = 5
    _x = 0
    _y = 0
    _xhistory = xhistory
    _yhistory = yhistory
    _position = position
  }

  update() {
    var x = _xhistory.count - (_position * _w) - 1
    var y = _yhistory.count - (_position * _h) - 1

    if (x >= 0 && y >= 0) {
      _x = _xhistory[x]
      _y = _yhistory[y]
    }
  }

  draw() {
    Canvas.rectfill(_x, _y, _w, _h, Color.green)
  }

  x { _x }
  y { _y }
  w { _w }
  h { _h }
}

var OurRandom = Random.new()

class Fruit {
  construct new() {
    _x = OurRandom.int(Canvas.width)
    _y = OurRandom.int(Canvas.height)
    _w = 2
    _h = 2
  }

  draw() {
    Canvas.rectfill(_x, _y, _w, _h, Color.red)
  }

  x { _x }
  y { _y }
  w { _w }
  h { _h }
}

class GameOverState {
  static next { __next}

  static init() {
    __next = null
    __hold = 0
  }

  static update() {
    var gamepad = GamePad.next

    if (Keyboard.isKeyDown("escape") || gamepad.isButtonPressed("guide")) {
      Process.exit()
    }
    if (Keyboard.isKeyDown("space") || gamepad.isButtonPressed("start")) {
      __hold = __hold + 1
      if (__hold > 4) {
        __next = MainGame
      }
    } else {
      __hold = 0
    }
  }

  static draw(dt) {
    Canvas.cls()
    Canvas.print("Game Over", (Canvas.width / 2) - 35, (Canvas.height / 2), Color.white)
  }
}