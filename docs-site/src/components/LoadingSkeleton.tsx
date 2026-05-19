'use client';

import { motion } from 'framer-motion';

const skeletonVariants = {
  animate: {
    opacity: [0.5, 1, 0.5],
    transition: {
      duration: 1.5,
      repeat: Infinity,
      ease: 'easeInOut',
    },
  },
};

export function LoadingSkeleton() {
  return (
    <div className="space-y-8">
      {/* Header skeleton */}
      <div className="space-y-4">
        <motion.div
          variants={skeletonVariants}
          animate="animate"
          className="h-12 bg-slate-200 dark:bg-slate-800 rounded-lg w-3/4"
        />
        <motion.div
          variants={skeletonVariants}
          animate="animate"
          className="h-4 bg-slate-200 dark:bg-slate-800 rounded w-full"
        />
        <motion.div
          variants={skeletonVariants}
          animate="animate"
          className="h-4 bg-slate-200 dark:bg-slate-800 rounded w-5/6"
        />
      </div>

      {/* Content skeleton - 3 cards */}
      <div className="grid md:grid-cols-3 gap-8">
        {[1, 2, 3].map((idx) => (
          <motion.div
            key={idx}
            variants={skeletonVariants}
            animate="animate"
            className="glass rounded-2xl p-8 space-y-4"
          >
            <div className="h-12 w-12 bg-slate-200 dark:bg-slate-800 rounded-lg" />
            <div className="h-6 bg-slate-200 dark:bg-slate-800 rounded w-3/4" />
            <div className="space-y-2">
              <div className="h-4 bg-slate-200 dark:bg-slate-800 rounded w-full" />
              <div className="h-4 bg-slate-200 dark:bg-slate-800 rounded w-5/6" />
            </div>
          </motion.div>
        ))}
      </div>
    </div>
  );
}

export function DocsSkeleton() {
  return (
    <div className="space-y-12">
      {/* Title skeleton */}
      <div className="text-center space-y-4">
        <motion.div
          variants={skeletonVariants}
          animate="animate"
          className="h-12 bg-slate-200 dark:bg-slate-800 rounded-lg mx-auto w-2/3"
        />
        <motion.div
          variants={skeletonVariants}
          animate="animate"
          className="h-6 bg-slate-200 dark:bg-slate-800 rounded-lg mx-auto w-3/4"
        />
      </div>

      {/* Cards skeleton */}
      <div className="grid md:grid-cols-2 gap-8">
        {[1, 2, 3, 4].map((idx) => (
          <motion.div
            key={idx}
            variants={skeletonVariants}
            animate="animate"
            className="glass rounded-2xl p-8 space-y-4"
          >
            <div className="h-8 bg-slate-200 dark:bg-slate-800 rounded w-2/3" />
            <div className="space-y-2">
              <div className="h-4 bg-slate-200 dark:bg-slate-800 rounded w-full" />
              <div className="h-4 bg-slate-200 dark:bg-slate-800 rounded w-5/6" />
            </div>
            <div className="space-y-3 pt-4">
              {[1, 2, 3].map((link) => (
                <div key={link} className="h-4 bg-slate-200 dark:bg-slate-800 rounded w-4/5" />
              ))}
            </div>
          </motion.div>
        ))}
      </div>
    </div>
  );
}

export function PageSkeleton() {
  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="min-h-screen space-y-8 py-16"
    >
      <LoadingSkeleton />
    </motion.div>
  );
}
