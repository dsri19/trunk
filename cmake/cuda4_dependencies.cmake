################################################
#
#  Set default versions of 3rd_party libraries
#
################################################

# set required protocol buffers version
SET(PROTOBUF_REQUIRED_VERSION "2.3.0")

# set Qt version
if (MSVC80)
	SET(QT_REQUIRED_VERSION "4.4.3")
else ()
	SET(QT_REQUIRED_VERSION "4.6.2")
endif()

# set zlib version
SET(ZLIB_REQUIRED_VERSION "1.2.5")

# set ogg version
SET(OGG_REQUIRED_VERSION "1.2.1")

# set vorbis version
SET(VORBIS_REQUIRED_VERSION "1.2.3")

# set theora version
SET(THEORA_REQUIRED_VERSION "1.1.1")

# set jthread version
SET(JTHREAD_REQUIRED_VERSION "1.2.1")     # required by jrtplib, don't change

# set jthread version
SET(JRTP_REQUIRED_VERSION "3.8.1")

# set libpng version
SET(PNG_REQUIRED_VERSION "1.4.2")

# set CUDA version
SET(CUDA_REQUIRED_VERSION "4.0")

# set Equalizer version
SET(EQUALIZER_REQUIRED_VERSION "11_0")

# set python version
SET(PYTHON_REQUIRED_VERSION "2.6.6")

# set Equalizer version
SET(IMAGEMAGICK_REQUIRED_VERSION "6.6.1")

# set JPEG version
SET(JPEG_REQUIRED_VERSION "8b")

# set TIFF version
SET(TIFF_REQUIRED_VERSION "3.9.2")

# set ICU version
SET(ICU_REQUIRED_VERSION "4.4.2")

# set glew version
SET(GLEW_REQUIRED_VERSION "1.5.3")

# set default JSON parser lib Yajl version
SET(YAJL_REQUIRED_VERSION "2.0.1")

# set zlib version
SET(LCMS_REQUIRED_VERSION "2.0")
