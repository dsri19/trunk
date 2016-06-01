find_package(OpenGL REQUIRED)

__rtt_system_library(opengl
	IMPLIB
		${OPENGL_LIBRARIES}

	INCLUDES
		${OPENGL_INCLUDE_DIR}

	LOCATION
		${OPENGL_LOCATION}
)
