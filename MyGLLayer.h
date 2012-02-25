#include "Config.h"

@interface MyGLLayer : CAOpenGLLayer {
	int fboWidth;
	int fboHeight;
	GLuint fbo;
	GLuint fboDepthBuffer;
	GLuint fboColorBuffer;
}

@end
