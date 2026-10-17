'use client'

import React, { useState, useEffect, type ReactNode } from 'react'
import { Swiper, SwiperSlide } from 'swiper/react'
import type { Swiper as SwiperType } from 'swiper'
import { Pagination, Mousewheel } from 'swiper/modules'
import { cn } from '@/lib/utils'

// Import Swiper styles
import 'swiper/css'
import 'swiper/css/pagination'

// Định nghĩa kiểu dữ liệu cho props
interface CustomSwiperProps {
	children: ReactNode
	direction?: 'vertical' | 'horizontal'
	spaceBetween?: number
	slidesPerView?: number
	className?: string
	bulletActiveClass?: string
	bulletClass?: string
	onPageChange?: (pageIndex: number) => void
}

export function CustomSwiper({
	children,
	direction = 'vertical',
	spaceBetween = 16,
	slidesPerView = 3,
	className = '',
	bulletActiveClass = 'bg-red-600 w-2 h-6',
	bulletClass = 'bg-gray-500 w-2 h-2',
	onPageChange
}: CustomSwiperProps) {
	const [activePageIndex, setActivePageIndex] = useState(0)
	const [swiperInstance, setSwiperInstance] = useState<SwiperType | null>(null)
	const [totalPages, setTotalPages] = useState(0)

	const childrenArray = React.Children.toArray(children)

	useEffect(() => {
		const calculatedPages = Math.ceil(childrenArray.length / slidesPerView)
		setTotalPages(calculatedPages)
	}, [childrenArray.length, slidesPerView])

	const slideGroups = []
	for (let i = 0; i < childrenArray.length; i += slidesPerView) {
		slideGroups.push(childrenArray.slice(i, i + slidesPerView))
	}

	const handleSlideChange = (swiper: SwiperType) => {
		const newPageIndex = swiper.activeIndex
		setActivePageIndex(newPageIndex)

		if (onPageChange) {
			onPageChange(newPageIndex)
		}
	}

	const handleBulletClick = (pageIndex: number) => {
		if (pageIndex < 0 || pageIndex >= totalPages) return
		if (pageIndex === activePageIndex) return
		if (swiperInstance) {
			swiperInstance.slideTo(pageIndex)
		}
	}

	return (
		<div className={cn('custom-swiper-container relative', className)}>
			{totalPages > 0 && (
				<div className='absolute left-2 top-1/2 -translate-y-1/2 z-10 flex flex-col gap-2'>
					{Array.from({ length: totalPages }).map((_, index) => (
						<button
							key={index}
							className={cn(
								'rounded-sm transition-all duration-300',
								index === activePageIndex ? bulletActiveClass : bulletClass
							)}
							onClick={() => handleBulletClick(index)}
							aria-label={`Đi đến trang ${index + 1}`}
						/>
					))}
				</div>
			)}

			<Swiper
				onSwiper={(swiper) => {
					setSwiperInstance(swiper)
				}}
				direction={direction}
				spaceBetween={spaceBetween}
				slidesPerGroup={1}
				slidesPerView={1}
				mousewheel={true}
				modules={[Pagination, Mousewheel]}
				className='h-full w-full'
				onSlideChange={handleSlideChange}
			>
				{slideGroups.map((group, groupIndex) => (
					<SwiperSlide key={groupIndex} className='pl-[1.25vw]'>
						<div className='flex flex-col space-y-2'>
							{group.map((child, childIndex) => (
								<div key={childIndex}>{child}</div>
							))}
						</div>
					</SwiperSlide>
				))}
			</Swiper>
		</div>
	)
}
