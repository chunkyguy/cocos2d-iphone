/*
 * cocos2d for iPhone: http://www.cocos2d-iphone.org
 *
 * Copyright (c) 2013-2014 Cocos2D Authors
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */


#import <stdarg.h>

#import "Platforms/CCGL.h"

#import "CCNodeColor.h"
#import "CCDirector.h"
#import "ccMacros.h"
#import "CCShader.h"
#import "Support/CGPointExtension.h"
#import "CCNode_Private.h"

#ifdef __CC_PLATFORM_IOS
#import "Platforms/iOS/CCDirectorIOS.h"
#elif defined(__CC_PLATFORM_MAC)
#import "Platforms/Mac/CCDirectorMac.h"
#endif

#pragma mark -
#pragma mark Layer

#if __CC_PLATFORM_IOS

#endif // __CC_PLATFORM_IOS

#pragma mark -
#pragma mark LayerColor

@implementation CCNodeColor {
	@protected
	GLKVector4	_colors[4];
}

+ (id) nodeWithColor:(CCColor*)color width:(GLfloat)w  height:(GLfloat) h
{
	return [[self alloc] initWithColor:color width:w height:h];
}

+ (id) nodeWithColor:(CCColor*)color
{
	return [(CCNodeColor*)[self alloc] initWithColor:color];
}

-(id) init
{
	CGSize s = [CCDirector sharedDirector].designSize;
	return [self initWithColor:[CCColor clearColor] width:s.width height:s.height];
}

// Designated initializer
- (id) initWithColor:(CCColor*)color width:(GLfloat)w  height:(GLfloat) h
{
	if( (self=[super init]) ) {
		self.blendMode = [CCBlendMode premultipliedAlphaMode];

		_displayColor = _color = color.ccColor4f;
		[self updateColor];
		[self setContentSize:CGSizeMake(w, h) ];

		self.shader = [CCShader positionColorShader];
	}
	return self;
}

- (id) initWithColor:(CCColor*)color
{
	CGSize s = [CCDirector sharedDirector].designSize;
	return [self initWithColor:color width:s.width height:s.height];
}

- (void) updateColor
{
	GLKVector4 color = GLKVector4Make(_displayColor.r*_displayColor.a, _displayColor.g*_displayColor.a, _displayColor.b*_displayColor.a, _displayColor.a);
	for(int i=0; i<4; i++) _colors[i] = color;
}

-(void)draw:(CCRenderer *)renderer transform:(const GLKMatrix4 *)transform
{
	CGSize size = self.contentSizeInPoints;
	GLKVector2 hs = GLKVector2Make(size.width*0.5f, size.height*0.5f);
	if(!CCRenderCheckVisbility(transform, hs, hs)) return;
	
	GLKVector2 zero = GLKVector2Make(0, 0);
	
	CCRenderBuffer buffer = [renderer enqueueTriangles:2 andVertexes:4 withState:self.renderState globalSortOrder:0];
	
	float w = size.width, h = size.height;
	CCRenderBufferSetVertex(buffer, 0, (CCVertex){GLKMatrix4MultiplyVector4(*transform, GLKVector4Make(0, 0, 0, 1)), zero, zero, _colors[0]});
	CCRenderBufferSetVertex(buffer, 1, (CCVertex){GLKMatrix4MultiplyVector4(*transform, GLKVector4Make(w, 0, 0, 1)), zero, zero, _colors[1]});
	CCRenderBufferSetVertex(buffer, 2, (CCVertex){GLKMatrix4MultiplyVector4(*transform, GLKVector4Make(w, h, 0, 1)), zero, zero, _colors[2]});
	CCRenderBufferSetVertex(buffer, 3, (CCVertex){GLKMatrix4MultiplyVector4(*transform, GLKVector4Make(0, h, 0, 1)), zero, zero, _colors[3]});
	
	CCRenderBufferSetTriangle(buffer, 0, 0, 1, 2);
	CCRenderBufferSetTriangle(buffer, 1, 0, 2, 3);
}

#pragma mark Protocols
// Color Protocol

-(void) setColor:(CCColor *)color
{
	[super setColor:color];
	[self updateColor];
}

-(void) setOpacity: (CGFloat) opacity
{
	[super setOpacity:opacity];
	[self updateColor];
}
@end


#pragma mark -
#pragma mark LayerGradient

@implementation CCNodeGradient

@synthesize vector = _vector;

+ (id) nodeWithColor: (CCColor*) start fadingTo: (CCColor*) end
{
    return [[self alloc] initWithColor:start fadingTo:end];
}

+ (id) nodeWithColor: (CCColor*) start fadingTo: (CCColor*) end alongVector: (CGPoint) v
{
    return [[self alloc] initWithColor:start fadingTo:end alongVector:v];
}

- (id) init
{
	return [self initWithColor:[CCColor blackColor] fadingTo:[CCColor blackColor]];
}

- (id) initWithColor: (CCColor*) start fadingTo: (CCColor*) end
{
    return [self initWithColor:start fadingTo:end alongVector:ccp(0, -1)];
}

- (id) initWithColor: (CCColor*) start fadingTo: (CCColor*) end alongVector: (CGPoint) v
{
	_color = start.ccColor4f;
	_endColor = end.ccColor4f;
	_vector = v;

	return [super initWithColor:start];
}

- (void) updateColor
{
	[super updateColor];
	
	// _vector apparently points towards the first color.
	float g0 = 0.0f; // (0, 0) dot _vector
	float g1 = -_vector.x; // (0, 1) dot _vector
	float g2 = -_vector.x - _vector.y; // (1, 1) dot _vector
	float g3 = -_vector.y; // (1, 0) dot _vector
	
	float gmin = MIN(MIN(g0, g1), MIN(g2, g3));
	float gmax = MAX(MAX(g0, g1), MAX(g2, g3));
	
	GLKVector4 a = GLKVector4Make(_color.r*_color.a, _color.g*_color.a, _color.b*_color.a, _color.a);
	GLKVector4 b = GLKVector4Make(_endColor.r*_endColor.a, _endColor.g*_endColor.a, _endColor.b*_endColor.a, _endColor.a);
	_colors[0] =  GLKVector4Lerp(a, b, (g0 - gmin)/(gmax - gmin));
	_colors[1] =  GLKVector4Lerp(a, b, (g1 - gmin)/(gmax - gmin));
	_colors[2] =  GLKVector4Lerp(a, b, (g2 - gmin)/(gmax - gmin));
	_colors[3] =  GLKVector4Lerp(a, b, (g3 - gmin)/(gmax - gmin));
}

-(CCColor*) startColor
{
	return [CCColor colorWithCcColor4f: _color];
}

-(void) setStartColor:(CCColor*)color
{
	[self setColor:color];
}

- (CCColor*) endColor
{
	return [CCColor colorWithCcColor4f:_endColor];
}

-(void) setEndColor:(CCColor*)color
{
	_endColor = color.ccColor4f;
	[self updateColor];
}

- (CGFloat) startOpacity
{
	return _color.a;
}

-(void) setStartOpacity: (CGFloat) o
{
	_color.a = o;
	[self updateColor];
}

- (CGFloat) endOpacity
{
	return _endColor.a;
}

-(void) setEndOpacity: (CGFloat) o
{
	_endColor.a = o;
	[self updateColor];
}

-(void) setVector: (CGPoint) v
{
	_vector = v;
	[self updateColor];
}

// Deprecated
-(BOOL) compressedInterpolation {return YES; }
-(void) setCompressedInterpolation:(BOOL)compress {}

@end


#pragma mark -
#pragma mark CCNodeGradientRadial

/** Get a radial mix value between [0.0, 1.0)
 * If num = 6; and gradientFactor = 1; for value of i returns
 * 0: 0.00
 * 1: 0.33
 * 2: 0.67
 * 3: 1.00
 * 4: 0.67
 * 5: 0.33
 *
 * If num = 6; and gradientFactor = 2; for value of i returns
 * 0: 0.00
 * 1: 0.17
 * 2: 0.33
 * 3: 0.50
 * 4: 0.33
 * 5: 0.17
 
 */
static inline float RadialMix(const int i, const int num, const float gradientFactor)
{
    float mid = num/2.0f;
    return (mid - fabs(mid - i)) / (mid * gradientFactor);
}

/** Linerly interpolate two vectors */
static inline ccVertex2F ccVertex2FLerp(const ccVertex2F start, const ccVertex2F end, float t)
{
    ccVertex2F ret;
    ret.x = start.x + (end.x - start.x) * t;
    ret.y = start.y + (end.y - start.y) * t;
    
    return ret;
}

@interface CCNodeGradientRadial () {
    ccColor4F _endColor;
    CGFloat _gradient;
}

- (void)updatePosition;
-(void) updateColor;

@end

@implementation CCNodeGradientRadial

// Opacity and RGB color protocol
@synthesize blendFunc = _blendFunc;

+ (id) nodeWithColor:(CCColor*)color width:(GLfloat)w  height:(GLfloat) h
{
	return [[self alloc] initWithColor:color width:w height:h];
}

+ (id) nodeWithColor:(CCColor*)color
{
	return [(CCNodeGradientRadial*)[self alloc] initWithColor:color];
}

+ (id) nodeWithColor: (CCColor*) start fadingTo: (CCColor*) end
{
    return [[self alloc] initWithColor:start fadingTo:end];
}

- (id) init
{
	return [self initWithColor:[CCColor blackColor] fadingTo:[CCColor blackColor]];
}

- (id) initWithColor: (CCColor*) start fadingTo: (CCColor*) end
{
	_color = start.ccColor4f;
	_endColor = end.ccColor4f;
    
	return [self initWithColor:start];
}

- (id) initWithColor:(CCColor*)color
{
	CGSize s = [CCDirector sharedDirector].designSize;
	return [self initWithColor:color width:s.width height:s.height];
}

// Designated initializer
- (id) initWithColor:(CCColor*)color width:(GLfloat)w  height:(GLfloat) h
{
	if( (self=[super init]) ) {
        
		// default blend function
		_blendFunc = (ccBlendFunc) { GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA };
        
		_displayColor = _color = color.ccColor4f;
        
        _gradient = 3.0f;
        
		for (NSUInteger i = 0; i<sizeof(_fanVertices) / sizeof( _fanVertices[0]); i++ ) {
			_fanVertices[i].x = 0.0f;
			_fanVertices[i].y = 0.0f;
		}
        
		[self updateColor];
		[self setContentSize:CGSizeMake(w, h) ];
        
		self.shaderProgram = [[CCShaderCache sharedShaderCache] programForKey:kCCShader_PositionColor];
	}
	return self;
}

- (void) draw
{
    [self updatePosition];
    
	CC_NODE_DRAW_SETUP();
    
	ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position | kCCVertexAttribFlag_Color );
    
	//
	// Attributes
	//
	glVertexAttribPointer(kCCVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, 0, _fanVertices);
	glVertexAttribPointer(kCCVertexAttrib_Color, 4, GL_FLOAT, GL_FALSE, 0, _fanColors);
    
	ccGLBlendFunc( _blendFunc.src, _blendFunc.dst );
    
	glDrawArrays(GL_TRIANGLE_FAN, 0, kCCNodeGradientRadialVertexCount(kCCNodeGradientRadialResolution));
	
	CC_INCREMENT_GL_DRAWS(1);
}

- (void)updatePosition
{
    CGSize size = self.contentSizeInPoints;
    
    /* calc position data */
    ccVertex2F posEdges[5] = {
        {size.width/2.0f, size.height/2.0f},    /* center */
        {0.0f,               0.0f},             /* bottom-left */
        {size.width,      0.0f},                /* bottom-right */
        {size.width,      size.height},         /* top-right */
        {0.0f,            size.height}          /* top-left */
    };
        
    int v = 0;

    /* center */
    memcpy(&_fanVertices[v++], &posEdges[0], sizeof(posEdges[0]));

    /** edges index
     * e : [eBegin,  eEnd]
     * 0 : [1,          2] : bottom
     * 1 : [2,          3] : right
     * 2 : [3,          4] : top
     * 3 : [4,          1] : left
     */
    for (int e = 0; e < 4; ++e) {
        
        int eBegin = e + 1;
        int eEnd = (e+1)%4 + 1;
        
        for (int r = 0; r < kCCNodeGradientRadialResolution; ++r) {
            
            ccVertex2F pos = ccVertex2FLerp(posEdges[eBegin], posEdges[eEnd],
                                            r/(float)kCCNodeGradientRadialResolution);
            memcpy(&_fanVertices[v++], &pos, sizeof(pos));
        }
    }
    
    /* close the loop */
    memcpy(&_fanVertices[v++], &posEdges[1], sizeof(posEdges[0]));
}

- (void) updateColor
{
	for( NSUInteger i = 0; i < sizeof(_fanColors)/sizeof(_fanColors[0]); i++ )
	{
		_fanColors[i] = _displayColor;
	}

    /* calculate color data */
    int v = 0;
    
    /* center */
    memcpy(&_fanColors[v++], &_color, sizeof(_color));
    
    /** edges index
     * e : [eBegin,  eEnd]
     * 0 : [1,          2] : bottom
     * 1 : [2,          3] : right
     * 2 : [3,          4] : top
     * 3 : [4,          1] : left
     */
    for (int e = 0; e < 4; ++e) {
        
        int eBegin = e + 1;
        int eEnd = (e+1)%4 + 1;
        
        for (int r = 0; r < kCCNodeGradientRadialResolution; ++r) {

            ccColor4F clr = ccc4FInterpolated(_endColor, _color, RadialMix(r, kCCNodeGradientRadialResolution, _gradient));
            memcpy(&_fanColors[v++], &clr, sizeof(clr));
        }
    }
    
    /* close the loop */
    memcpy(&_fanColors[v++], &_endColor, sizeof(_endColor));
}

-(CCColor*) startColor
{
	return [CCColor colorWithCcColor4f: _color];
}

-(void) setStartColor:(CCColor*)color
{
	[self setColor:color];
}

- (CCColor*) endColor
{
	return [CCColor colorWithCcColor4f:_endColor];
}

-(void) setEndColor:(CCColor*)color
{
	_endColor = color.ccColor4f;
	[self updateColor];
}

- (CGFloat) startOpacity
{
	return _color.a;
}

-(void) setStartOpacity: (CGFloat) o
{
	_color.a = o;
	[self updateColor];
}

- (CGFloat) endOpacity
{
	return _endColor.a;
}

-(void) setEndOpacity: (CGFloat) o
{
	_endColor.a = o;
	[self updateColor];
}

- (CGFloat) gradientFactor
{
    return _gradient;
}

- (void)setGradientFactor:(CGFloat)gradientFactor
{
    NSAssert(gradientFactor > 0.0,
             @"gradientFactor should always have a value greater than 0.0.\n"
             "gradientFactor controls the smoothness of the interpolation between the two colors\n"
             "Ideally it should be >= 3.0.");

    _gradient = gradientFactor;
    [self updateColor];
}

#pragma mark Protocols
// Color Protocol

-(void) setColor:(CCColor*)color
{
	[super setColor:color];
	[self updateColor];
}

-(void) setOpacity: (CGFloat) opacity
{
	[super setOpacity:opacity];
	[self updateColor];
}

@end

#pragma mark -
#pragma mark MultiplexLayer

@implementation CCNodeMultiplexer
+(id) nodeWithArray:(NSArray *)arrayOfNodes
{
	return [[self alloc] initWithArray:arrayOfNodes];
}

+(id) nodeWithNodes: (CCNode*) layer, ...
{
	va_list args;
	va_start(args,layer);

	id s = [[self alloc] initWithLayers: layer vaList:args];

	va_end(args);
	return s;
}

-(id) initWithArray:(NSArray *)arrayOfNodes
{
	if( (self=[super init])) {
		_nodes = [arrayOfNodes mutableCopy];

		_enabledNode = 0;

		[self addChild: [_nodes objectAtIndex:_enabledNode]];
	}


	return self;
}

-(id) initWithLayers: (CCNode*) node vaList:(va_list) params
{
	if( (self=[super init]) ) {

		_nodes = [NSMutableArray arrayWithCapacity:5];

		[_nodes addObject: node];

		CCNode *l = va_arg(params,CCNode*);
		while( l ) {
			[_nodes addObject: l];
			l = va_arg(params,CCNode*);
		}

		_enabledNode = 0;
		[self addChild: [_nodes objectAtIndex: _enabledNode]];
	}

	return self;
}


-(void) switchTo: (unsigned int) n
{
	NSAssert( n < [_nodes count], @"Invalid index in MultiplexLayer switchTo message" );

	[self removeChild: [_nodes objectAtIndex:_enabledNode] cleanup:YES];

	_enabledNode = n;

	[self addChild: [_nodes objectAtIndex:n]];
}

-(void) switchToAndReleaseMe: (unsigned int) n
{
	NSAssert( n < [_nodes count], @"Invalid index in MultiplexLayer switchTo message" );

	[self removeChild: [_nodes objectAtIndex:_enabledNode] cleanup:YES];

	[_nodes replaceObjectAtIndex:_enabledNode withObject:[NSNull null]];

	_enabledNode = n;

	[self addChild: [_nodes objectAtIndex:n]];
}
@end
