import * as React from 'react'

export interface ImageProps extends React.ImgHTMLAttributes<HTMLImageElement> {
	fallbackSrc?: string
}

export const Image = React.forwardRef<HTMLImageElement, ImageProps>(({ src, alt, fallbackSrc, ...props }, ref) => {
	const [imgSrc, setImgSrc] = React.useState(src)
	return <img ref={ref} src={imgSrc} alt={alt} onError={() => fallbackSrc && setImgSrc(fallbackSrc)} {...props} />
})
Image.displayName = 'Image'
