import { Skeleton } from '@/components/ui/skeleton'
import { cn } from '@/lib/utils'

export default function LoadingContent({ className = '', rows = 5 }: { className?: string; rows?: number }) {
	return (
		<div className={cn(`flex flex-col gap-[1.25vh] p-[1.25vh]`, className)}>
			{Array.from({ length: rows }).map((_, i) => (
				<div className='flex h-[4vh] gap-4' key={i}>
					<Skeleton className='w-16' />
					<Skeleton className='w-40' />
					<Skeleton className='flex-1' />
					<Skeleton className='w-24' />
					<Skeleton className='w-20' />
				</div>
			))}
		</div>
	)
}
