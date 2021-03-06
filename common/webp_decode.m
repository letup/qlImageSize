//
//  webp_decode.m
//  qlImageSize
//
//  Created by @Nyx0uf on 30/12/14.
//  Copyright (c) 2014 Nyx0uf. All rights reserved.
//


#import "webp_decode.h"
#import "decode.h"


#ifdef NYX_QL_SUPPORT_WEBP_DECODE
CF_RETURNS_RETAINED CGImageRef decode_webp_at_path(CFStringRef filepath, image_infos* infos)
{
	// Init WebP decoder
	WebPDecoderConfig webp_cfg;
	if (!WebPInitDecoderConfig(&webp_cfg))
		return NULL;

	// Read file
	uint8_t* buffer = NULL;
	const size_t file_size = read_file(filepath, &buffer);
	if (0 == file_size)
	{
		free(buffer);
		return NULL;
	}

	// Get image infos
	if (WebPGetFeatures(buffer, file_size, &webp_cfg.input) != VP8_STATUS_OK)
	{
		free(buffer);
		return NULL;
	}

	// Decode image, always RGBA
	webp_cfg.output.colorspace = MODE_rgbA;
	if (WebPDecode(buffer, file_size, &webp_cfg) != VP8_STATUS_OK)
	{
		free(buffer);
		return NULL;
	}
	free(buffer);

	if (infos != NULL)
	{
		infos->width = (size_t)webp_cfg.input.width;
		infos->height = (size_t)webp_cfg.input.height;
		infos->filesize = (size_t)file_size;
	}

	// Create CGImage
	CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();
	CGContextRef ctx = CGBitmapContextCreate(webp_cfg.output.u.RGBA.rgba, (size_t)webp_cfg.input.width, (size_t)webp_cfg.input.height, 8, 4 * (size_t)webp_cfg.input.width, color_space, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast);
	CGColorSpaceRelease(color_space);
	WebPFreeDecBuffer(&webp_cfg.output);
	CGImageRef img_ref = CGBitmapContextCreateImage(ctx);
	CGContextRelease(ctx);
	return img_ref;
}
#endif /* NYX_QL_SUPPORT_WEBP_DECODE */

#ifdef NYX_MD_SUPPORT_WEBP_DECODE
bool get_webp_informations_for_filepath(CFStringRef filepath, image_infos* infos)
{
	WebPDecoderConfig webp_cfg;
	if (!WebPInitDecoderConfig(&webp_cfg))
		return false;

	// Read file
	uint8_t* buffer = NULL;
	const size_t size = read_file(filepath, &buffer);
	if (0 == size)
	{
		free(buffer);
		return false;
	}

	// Get file informations
	if (WebPGetFeatures(buffer, size, &webp_cfg.input) != VP8_STATUS_OK)
	{
		free(buffer);
		return false;
	}
	free(buffer);

	infos->width = (size_t)webp_cfg.input.width;
	infos->height = (size_t)webp_cfg.input.height;
	infos->has_alpha = (uint8_t)webp_cfg.input.has_alpha;
	infos->bit_depth = 8;
	infos->colorspace = (webp_cfg.input.format == 2) ? colorspace_rgb : colorspace_ycbcr; // lossy WebP, always YUV 4:2:0 | lossless WebP, always ARGB

	return true;
}
#endif /* NYX_MD_SUPPORT_WEBP_DECODE */
