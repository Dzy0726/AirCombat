# AirCombat

## 1 项目概述

### 1.1 项目说明

该项目是同济大学软件学院2020年移动应用开发的期末项目。AirCombat，即空中作战，是一款基于SceneKit开发的3D iOS游戏。

在游戏中，玩家通过控制手机来操控一架战机，躲避障碍物并穿过指定的圆环获得相应的分数，并在空中躲避敌人攻击并尽可能多的击落敌机获得更多的额外分数。

### 1.2 开发环境

**开发环境**：macOS Catalina10.15.6 + Xcode 12.2 (12B45b)

**开发语言**：Swift5 + SceneKit

**测试工具**：Simulator iPhone 12 Pro Max iOS 14.2

### 1.3 功能点介绍

- [x] 地形生成
- [x] 随机障碍物生成
- [x] 圆环随机位置
- [x] 通过左右前后晃动手机控制飞机
- [x] 子弹管理
- [x] 敌机、敌机自动攻击
- [x] 攻击和击落
- [x] 计分牌
- [x] 音效：攻击、穿过圆环、坠毁

### 1.4 项目截图

![image-20210103140118353](/Users/dzy/Library/Application Support/typora-user-images/image-20210103140118353.png)

![image-20210103140126355](/Users/dzy/Library/Application Support/typora-user-images/image-20210103140126355.png)



## 2 核心功能

### 2.1 游戏循环与状态

在游戏过程中，游戏循环会连续运行。每次循环，它都会处理用户输入而不会阻塞，更新游戏状态并渲染游戏。它随着时间控制游戏。SceneKit允许在框架中的多个时间通过设置委托并实现相关方法来进行挂接。

<img src="/Users/dzy/Library/Application Support/typora-user-images/image-20210103214130943.png" alt="image-20210103214130943" style="zoom:50%;" />

#### 2.1.1 游戏状态

- 初始化(initialized): 游戏(GameLevel)刚刚创建，但还没有开始
- 游戏(play): 游戏目前正在进行中
- 获胜(win): 游戏获胜结束
- 失败(lose): 游戏失败结束
- 停止(stopped): 游戏已停止(所有动作终止)

基于此，通过飞机穿过的环和没有穿过的环的和是否等于设定的总数来判断游戏结束。

```swift
if _missedRings + _touchedRings == _numberOfRings {
  if _missedRings < 3 {
      _hud?.message("YOU WIN", information: "- Touch to restart - ")
  }
  else {
      _hud?.message("TRY TO IMPROVE", information: "- Touch to restart - ")
  }

  self.state = .win
}
```

如果碰到障碍物或敌机或被敌机击中，则游戏失败。

```swift
func touchedHandicap(_ handicap: Handicap) {
    _hud?.message("GAME OVER", information: "- Touch to restart - ")

    self.state = .lose
 }
```

#### 2.1.2 游戏对象的状态

所有的类（环、飞机、敌机、子弹等）均是GameObject的子类，将全部的游戏对象存储在一个列表中，在每一帧对它们进行迭代。

- 初始化(initialized):游戏对象刚刚创建
- 存在(alive):游戏对象存在
- 消亡(died):游戏对象消亡
- 停止(stopped): 游戏对象停止，所有资源被释放

### 2.2 地形的生成

#### 2.2.1 函数使用

**GameLevel.swift**中addTerrain()方法：

```swift
private func addTerrain() {
        // Create terrain
    _terrain = Terrain(width: Int(Game.Level.width), length: Int(Game.Level.length), scale: 96)
        
    let generator = PerlinNoiseGenerator(seed: nil)
    _terrain?.formula = {(x: Int32, y: Int32) in
         return generator.valueFor(x: x, y: y)
        }
        
    _terrain!.create(withColor: UIColor.green)
    _terrain!.position = SCNVector3Make(0, 0, 0)
    self.rootNode.addChildNode(_terrain!)
 }
```

Terrain类创建了类似于网格的对象，调用闭包函数为网格的每一组x,y坐标赋予一个高度就可以形成封闭的图形。然后使用**柏林噪声算法**生成类似于真实的“丘陵”地形。

#### 2.2.2 自定义3D对象

**SceneKit**中提供了许多基本的3D图形，如圆柱、圆锥、正方体和圆环等。要实现一个自定义的3D对象，需要用到**SCNGeometry类**。

> A three-dimensional shape (also called a model or mesh) that can be displayed in a scene, with attached materials that define its appearance.

创建几何对象用到的函数：

```swift
convenience init(sources: [SCNGeometrySource], elements: [SCNGeometryElement]?)
```

sources是一个对象数组，描述几何中的顶点及属性，而elements是一组对象，描述如何连接几何图形的顶点。

根据官方文档：

> You create a custom geometry using a three-step process:
>
> 1. Create one or more SCNGeometrySource objects containing vertex data. Each geometry source defines an attribute, or semantic, of the vertices it describes. You must provide at least one geometry source, using the vertex semantic, to create a custom geometry; typically you also provide geometry sources for surface normals and texture coordinates.
> 2. Create at least one SCNGeometryElement object, containing an array of indices identifying vertices in the geometry sources and describing the drawing primitive that SceneKit uses to connect the vertices when rendering the geometry.
> 3. Create an SCNGeometry instance from the geometry sources and geometry elements.

所以创建自定义3D对象需要**顶点列表**（定义一个网格）、**索引列表**（描述如何使用顶点连接）、**纹理列表**（如何将纹理或图形用于几何体）以及**法线列表**（定义如何将光用于对象）。

在**Terrain.swift**中通过createGeometry()方法实现自定义地形的3D对象。

1. 通过顶点列表创建给定大小的网格

   ```swift
   for y in 0...Int(h-2) {
     for x in 0...Int(w-1) {
     vertices[vertexCount] = bottomLeft
     vertices[vertexCount+1] = topLeft
     vertices[vertexCount+2] = topRight
     vertices[vertexCount+3] = bottomRight
     vertexCount += 4
   }
   ```

   然后用顶点列表创建一个几何源，并添加到sources数组中，便于后续用SCNGeometry的构造函数创建：

   ```swift
   let source = SCNGeometrySource(vertices: vertices)
   sources.append(source)
   ```

2. 创建索引列表，描述如何使用上面的顶点

   ```swift
   let geometryData = NSMutableData()
   var geometry: CInt = 0
   while (geometry < CInt(vertexCount)) {
     let bytes: [CInt] = [geometry, geometry+2, geometry+3, geometry, geometry+1, geometry+2]
     geometryData.append(bytes, length: sizeof(CInt.self)*6)
     geometry += 4
   }
   
   let element = SCNGeometryElement(data: geometryData as Data, primitiveType: .triangles, primitiveCount: vertexCount/2, bytesPerIndex: sizeof(CInt.self))
   ```

3. 纹理列表，将图像或纹理用于自定义的3D对象

   ```swift
   let uvData = NSData(bytes: uvList, length: uvList.count *  sizeof(vector_float2.self))
       let uvSource = SCNGeometrySource(data: uvData as Data,
               semantic: SCNGeometrySourceSemanticTexcoord,
               vectorCount: uvList.count,
               floatComponents: true,
               componentsPerVector: 2,
               bytesPerComponent: sizeof(Float.self),
               dataOffset: 0,
               dataStride: sizeof(vector_float2.self))
   ```

   其中，data是几何源的数据，semantic描述几何源每个顶点的属性如位置、颜色等，usesFloatComponents指示矢量分量是否为浮点数，componentsPerVector表示每个向量中标量分量的数量，bytesPerComponents表示每个向量分量的大小，dataOffSet指第一个矢量分量的偏移量，dataStride表示从向量到数据中下一个向量的字节数。

4. 法线列表

   ```swift
   for normalIndex in 0...vertexCount-1 {
     normals[normalIndex] = SCNVector3Make(0, 0, -1)
   }
   sources.append(SCNGeometrySource(normals: normals, count: vertexCount))
   ```

将这些都添加到**sources**和**element**中后，调用SCNGeometry构造函数：

```swift
_terrainGeometry = SCNGeometry(sources: sources, elements: elements)
```

#### 2.2.3 柏林噪声算法

一个噪声函数基本上是一个种子随机发生器。它需要一个整数作为参数，然后返回根据这个参数返回一个随机数。如果你两次都传同一个参数进来，它就会产生两次相同的数。

柏林噪声主要的流程是：首先获得随机值，平滑噪声（对噪声插值）形成一个连续的函数。最后叠加上面的那些带有不同频率和振幅的函数形成一个柏林噪声函数。

柏林噪声里面有两个主要的参数：persistence（持续度）和Octaves（倍频）。

**持续度：**持续度越大，振幅越大，对于图像而言图像更加混乱，对比更加突出，能看出更多细节。

**倍频：**每个你所叠加的噪声函数就是一个倍频，每一个噪声函数是上一个噪声函数的两倍频率。叠加每次的不同的频率是为了让图像在原有的噪声函数的基础上增加更多的细节信息。

在**PerlinNoiseGenerator.swift**中，我直接使用了[**Steven Troughton-Smith**](https://gist.github.com/steventroughtonsmith)的代码，取得了不错的效果。

### 2.3 碰撞检测

**SceneKit**中提供了容易实现的3D物体的碰撞检测。当SceneKit准备渲染新的帧时，它将对附着到场景节点上的物理物体执行物理计算。这些计算包括重力，摩擦以及与其他物体的碰撞。SceneKit还可以对物体施加自己的中立和冲力。SceneKit完成这些计算后，将在渲染框架之前更新节点对象的位置和方向。

> Use the [`categoryBitMask`](https://developer.apple.com/documentation/scenekit/scnphysicsbody/1514768-categorybitmask) and [`collisionBitMask`](https://developer.apple.com/documentation/scenekit/scnphysicsbody/1514772-collisionbitmask) properties to define an object’s collision behavior. The constants listed in [`SCNPhysicsCollisionCategory`](https://developer.apple.com/documentation/scenekit/scnphysicscollisioncategory) provide default values for these properties. In addition, with the [`contactTestBitMask`](https://developer.apple.com/documentation/scenekit/scnphysicsbody/1514746-contacttestbitmask) property you can define interactions where a pair of bodies generates contact messages (see the [`SCNPhysicsContactDelegate`](https://developer.apple.com/documentation/scenekit/scnphysicscontactdelegate) protocol) without the bodies being affected by the collision.

一个场景的physicsWorld属性拥有一个SCNPhysicsWorld对象，它管理影响整个场景的物理特性。处理整个场景内任意两个物体的碰撞，可以使用**SCNPhysicsContactDelegate**。

> To receive contact messages, you set the [`contactDelegate`](https://developer.apple.com/documentation/scenekit/scnphysicsworld/1512843-contactdelegate) property of an [`SCNPhysicsWorld`](https://developer.apple.com/documentation/scenekit/scnphysicsworld) object. SceneKit calls your delegate methods when a contact begins, when information about the contact changes, and when the contact ends.

**SCNPhysicsContactDelegate**提供了三个函数来处理两个物体的碰撞，分别在两个物体开始接触、有关信息发生变化和结束接触时调用。

所以进行物理碰撞检测的步骤如下：

1. 将`contact delegate`设置为场景，即`self.physicsWorld.contactDelegate = self`
2. 实现函数`physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact)`
3. 为节点添加物理实体
4. 设置类别位掩码`categoryBitMask`
5. 设置`categoryTestBitMask`获取需要的节点的联系消息。

#### 2.2.1 设置代理为场景本身

*GameLevel.swift*

```swift
override init() {
    super.init()
		self.physicsWorld.contactDelegate = self
}
```

#### 2.3.2 实现函数physicsWorld()

*GameLevel.swift*

```swift
func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
	if let gameObjectA = contact.nodeA.parent as? GameObject, let gameObjectB = contact.nodeB.parent as? GameObject {
	gameObjectA.collision(with: gameObjectB, level: self)
	gameObjectB.collision(with: gameObjectA, level: self)
	}
}
```

#### 2.3.3 为节点添加物理实体

下面以飞机和环的物理检测为例：

*Ring.swift - init()*

```swift
	let boxMaterial = SCNMaterial()
	boxMaterial.diffuse.contents = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.0)
	let box = SCNBox(width: 10.0, height: 10.0, length: 1.0, chamferRadius: 0.0)
	box.materials = [boxMaterial]
	let contactBox = SCNNode(geometry: box)
	contactBox.name = "ring"
	contactBox.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
```

*Plane.swift - init()*

```swift
	let boxMaterial = SCNMaterial()
	boxMaterial.diffuse.contents = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.0)
	let box = SCNBox(width: 2.0, height: 1.0, length: 1.0, chamferRadius: 0.0)
	box.materials = [boxMaterial]
	_collissionNode = SCNNode(geometry: box)
	_collissionNode!.name = "plane"
	_collissionNode!.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
```

其中**SCNPhysicsBody**的*type*决定物体在模拟中如何与力和其他物体相互作用。分为三种：

- Static:物体不受力和碰撞的影响，不能移动。
- Dynamic:物体受到力和与其他物体类型碰撞的影响。
- Kinematic:物体不受力或碰撞的影响，但是通过直接移动它们，可以引起影响动态物体的碰撞。

本游戏中所有的物体均为Kinematic类型。

#### 2.3.4 设置类别位掩码

*GameSettings.swift*

```swift
 struct Physics {
        // Category bits used for physics handling
        struct Categories {
            static let player: Int = 0b00000001
            static let ring:   Int = 0b00000010
            static let enemy:  Int = 0b00000100
            static let bullet: Int = 0b00001000
        }
    }
```

*Ring.swift - init()*

```swift
	contactBox.physicsBody?.categoryBitMask = Game.Physics.Categories.ring
```

*Plane.swift - init()*

```swift
 	_collissionNode!.physicsBody?.categoryBitMask = Game.Physics.Categories.player
```

#### 2.3.5 设置categoryTestBitMask

玩家的飞机类可能会与环或敌机发生碰撞，故设置需要获取这两种node的消息：

*Plane.swift - init()*

```swift
	_collissionNode!.physicsBody!.contactTestBitMask = Game.Physics.Categories.ring | Game.Physics.Categories.enemy
```

![image-20210103225710687](/Users/dzy/Library/Application Support/typora-user-images/image-20210103225710687.png)

#### 2.3.6 调用collision()

以*Player.swift*的collision方法为例：

首先检查自身状态，再判断collision with object（碰撞的物体）是什么类型，进行对应的处理。

```swift
override func collision(with object: GameObject, level: GameLevel) {
        if self.state != .alive {
            return
        }
        if let ring = object as? Ring {
            if ring.state != .alive {
                return
            }
            GameSound.bonus(self)
            level.flyTrough(ring)
            ring.hit()
        }
        else if let handicap = object as? Handicap {
            if self.state != .alive {
                return
            }
            GameSound.explosion(self)
            level.touchedHandicap(handicap)
            handicap.hit()
            self.die()
        }
        else if let enemy = object as? Enemy {
            if enemy.state != .alive {
                return
            }
            GameSound.explosion(self)
            enemy.hit()
            self.hit()
        }
    }
```

### 2.4 Core Motion的使用

左右滑动手机屏幕驾驶飞机不太符合实际，可以用CoreMotion使用包括来自加速度计，陀螺仪，计步器和磁力计的数据来访问硬件生成的数据，从而控制游戏。

> An application receives or samples CMDeviceMotion objects at regular intervals after calling the startDeviceMotionUpdates(using:to:withHandler:) method, the startDeviceMotionUpdates(to:withHandler:) method, the startDeviceMotionUpdates(using:) method, or the startDeviceMotionUpdates() method of the CMMotionManager class.

#### 2.4.1 存储加速度计的数据

设置三个变量如下：一个用于**CMMotionManager**本身，另外两个用于存储启动数据（稍后将详细介绍）和加速度计的当前数据。

`attitude`(类型：CMAttitude)

- 返回设备的方位信息，包含roll 、pitch、yaw三个欧拉角的值
- `roll`: 设备绕 Z 轴转过的角度
- `pitch`: 设备绕 X 轴转过的角度
- `yaw`: 设备绕 Y 轴转过的角度

```swift
private var _motionManager = CMMotionManager()
private var _startAttitude: CMAttitude?
private var _currentAttitude: CMAttitude?    
```

以下代码行启动CMMotionManager：

```swift
private func setupMotionHandler() {
  if (_motionManager.isAccelerometerAvailable) {
    _motionManager.accelerometerUpdateInterval = 1/60.0

    _motionManager.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: {(data, error) in
        self.motionDidChange(data: data!)
    })
  }
}
```

检查加速度计设备是否可用，如果有，调用startDeviceMotionUpdates()并分配闭包。现在以1 / 60.0秒的频率调用此块获取。`_startAttitude`是一个参考值，在玩家开始与此相关的动作之前，立即保存该参考值（初始值）；`_currentAttitude`获取当前用户左右移动或俯仰移动的数据。所有这些都是在motionDidChange()中完成的：

```swift
private func motionDidChange(data: CMDeviceMotion) {
  _currentAttitude = data.attitude

  guard _level != nil, _level?.state == .play else { return }

  // Up/Down
  let diff1 = _startAttitude!.roll - _currentAttitude!.roll

  if (diff1 >= Game.Motion.threshold) {
    _level!.motionMoveUp()
  }
  else if (diff1 <= -Game.Motion.threshold) {
    _level!.motionMoveDown()
  }
  else {
    _level!.motionStopMovingUpDown()
  }

  let diff2 = _startAttitude!.pitch - _currentAttitude!.pitch

  if (diff2 >= Game.Motion.threshold) {
    _level!.motionMoveLeft()
  }
  else if (diff2 <= -Game.Motion.threshold) {
    _level!.motionMoveRight()
  }
  else {
    _level!.motionStopMovingLeftRight()
  }
}
```

#### 2.4.2 使CoreMotion适配player

GameViewController中调用motionDidChange

1. 当差异大于等于0.2时，motionMoveUp()或motionMoveDown()
2. 差异小于0.2时调用motionStopMovingUpDown()

motionMoveUp中调用moveUp，各子类进行重写。

```swift
func moveUp() {
  let oldDirection = _upDownDirection

  if _upDownDirection == .none {
    let moveAction = SCNAction.moveBy(x: 0, y: Game.Player.upDownMoveDistance, z: 0, duration: 0.5)
    self.runAction(SCNAction.repeatForever(moveAction), forKey: "upDownDirection")

    _upDownDirection = .up
  }
  else if (_upDownDirection == .down) {
    self.removeAction(forKey: "upDownDirection")

    _upDownDirection = .none
  }

  if oldDirection != _upDownDirection {
    adjustCamera()
  }
}
```

```swift
func stopMovingUpDown() {
  let oldDirection = _upDownDirection

  self.removeAction(forKey: "upDownDirection")
  _upDownDirection = .none

  if oldDirection != _upDownDirection {
    adjustCamera()
  }
}
```

#### 2.4.3 使相机平滑移动

每当改变方向时都将摄像机的位置移动到播放器后面，但会延迟一点。使用SCNTransaction.begin()和SCNTransaction.end()，使用SCNTransaction.animationDuration = 1.0设置动画时间， 现在我们在中间所做的每个更改都将被动画化。

```swift
private func adjustCamera() {
        // move the camera according to the fly direction
        var position = _cameraNode!.position
        
        if (self.leftRightDirection == .left) {
            position.x = 1.0
        }
        else if (self.leftRightDirection == .right) {
            position.x = -1.0
        }
        else if (self.leftRightDirection == .none) {
            position.x = 0.1
        }
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1.0
        
        _cameraNode?.position = position
        
        SCNTransaction.commit()
    }
```

#### 2.4.4 向任何方向移动时稍微旋转飞机

*Player.swift*的 update()方法中(与相机类似)

```swift
SCNTransaction.begin()
SCNTransaction.animationDuration = 1.0
_playerNode?.eulerAngles = SCNVector3(eulerX, 0, eulerZ)
SCNTransaction.commit()
```



## 3 类概要说明

|         类名         |            功能说明             |
| :------------------: | :-----------------------------: |
|      GameLevel       |       游戏逻辑主要实现类        |
|      GameObject      |         游戏对象的基类          |
|       Handicap       |            障碍物类             |
|         Ring         |      游戏中可以穿过的环类       |
|        Bullet        |             子弹类              |
|        Plane         |             飞机类              |
|        Enemy         |       敌人类，继承自Plane       |
|        Player        |       玩家类，继承自Plane       |
|      GameSound       |             音效类              |
|     GameSettings     |      游戏设置类，设置参数       |
|         HUD          |         Head up display         |
|       Terrain        |             地形类              |
| PerlinNoiseGenerator |          PerlinNoise类          |
|         Log          |           记录输出类            |
|        Random        |            随机数类             |
|       Utility        |         角度和弧度转换          |
|       CGPoint        |     CGPoint扩展类，坐标运算     |
|      SCNVector       | 扩展类，计算两个vector3之间距离 |
|       SKAction       |        扩展类，文字效果         |
|       UIColor        |           颜色扩展类            |



## 4 项目总结

对于地形的实现，通过查看参考资料，了解了PerlinNoise算法，大致了解原理后，在github上找到了Steven Troughton-Smith先生的开源代码，我试着使用，取得了理想中的效果。

对于SceneKit套件，仔细阅读苹果公司官方的说明文档，了解了很多类及函数的使用方法。虽然阅读英文文档速度较慢，但能获得最直接的使用方法。

使用一些开源扩展类如CGPoint的扩展类可以极大提高开发速度，方便使用且易于理解。