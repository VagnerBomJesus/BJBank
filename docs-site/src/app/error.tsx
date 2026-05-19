'use client';

import { motion } from 'framer-motion';
import Link from 'next/link';
import { ArrowRight, AlertTriangle, RefreshCw } from 'lucide-react';
import { useEffect } from 'react';

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.2,
      delayChildren: 0.1,
    },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.8, ease: 'easeOut' },
  },
};

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <div className="relative min-h-screen flex items-center justify-center overflow-hidden bg-gradient-to-br from-slate-950 via-red-900/20 to-slate-950">
      {/* Animated background */}
      <div className="absolute inset-0 -z-10">
        <motion.div
          animate={{
            top: ['0%', '100%'],
            left: ['0%', '50%'],
          }}
          transition={{ duration: 20, repeat: Infinity, ease: 'easeInOut' }}
          className="absolute top-0 right-0 h-[600px] w-[600px] rounded-full bg-gradient-to-br from-red-600 to-pink-600 opacity-15 blur-3xl"
        />
        <motion.div
          animate={{
            bottom: ['0%', '100%'],
            right: ['0%', '50%'],
          }}
          transition={{ duration: 25, repeat: Infinity, ease: 'easeInOut', delay: 5 }}
          className="absolute bottom-0 left-0 h-[600px] w-[600px] rounded-full bg-gradient-to-tl from-orange-600 to-red-600 opacity-15 blur-3xl"
        />
        <div className="absolute inset-0 bg-grid-pattern opacity-5" />
      </div>

      <div className="relative z-10 max-w-2xl mx-auto px-6 py-20 text-center">
        <motion.div
          variants={containerVariants}
          initial="hidden"
          animate="visible"
          className="space-y-8"
        >
          {/* Animated alert icon */}
          <motion.div variants={itemVariants}>
            <motion.div
              animate={{ scale: [1, 1.1, 1], rotate: [0, 5, -5, 0] }}
              transition={{ duration: 4, repeat: Infinity, ease: 'easeInOut' }}
              className="inline-block"
            >
              <div className="w-20 h-20 md:w-24 md:h-24 rounded-full bg-gradient-to-br from-red-500 to-orange-500 flex items-center justify-center mx-auto">
                <AlertTriangle className="w-10 h-10 md:w-12 md:h-12 text-white" />
              </div>
            </motion.div>
          </motion.div>

          {/* Title */}
          <motion.div variants={itemVariants} className="space-y-4">
            <h1 className="text-4xl md:text-5xl font-bold">Something Went Wrong</h1>
            <p className="text-xl text-slate-400">
              We encountered an unexpected error while processing your request.
            </p>
          </motion.div>

          {/* Error Details */}
          <motion.div
            variants={itemVariants}
            className="glass rounded-2xl p-6 md:p-8 border border-white/10 text-left"
          >
            <p className="text-sm text-slate-300 font-mono">
              {error.message || 'An unexpected error occurred'}
            </p>
            {error.digest && (
              <p className="text-xs text-slate-500 mt-2">
                Error ID: {error.digest}
              </p>
            )}
          </motion.div>

          {/* CTA Buttons */}
          <motion.div
            variants={itemVariants}
            className="flex flex-col sm:flex-row gap-4 justify-center pt-4"
          >
            <motion.button
              onClick={reset}
              whileHover={{ scale: 1.05, y: -2 }}
              whileTap={{ scale: 0.95 }}
              className="group relative px-10 py-4 rounded-xl font-bold flex items-center justify-center gap-3 bg-gradient-to-r from-orange-500 to-red-500 text-white overflow-hidden"
            >
              <span className="absolute inset-0 bg-gradient-to-r from-white/0 via-white/30 to-white/0 translate-x-[-100%] group-hover:translate-x-[100%] transition-transform duration-500" />
              <span className="relative flex items-center gap-2">
                <RefreshCw className="w-5 h-5" />
                Try Again
              </span>
            </motion.button>

            <motion.div
              whileHover={{ scale: 1.05, y: -2 }}
              whileTap={{ scale: 0.95 }}
            >
              <Link
                href="/"
                className="px-10 py-4 rounded-xl font-bold flex items-center justify-center gap-3 glass border border-blue-500/30 hover:border-blue-500/60 transition-all text-white hover:bg-white/10 w-full sm:w-auto"
              >
                <span className="relative flex items-center gap-2">
                  Back to Home
                  <ArrowRight className="w-5 h-5" />
                </span>
              </Link>
            </motion.div>
          </motion.div>

          {/* Support info */}
          <motion.div
            variants={itemVariants}
            className="pt-8 space-y-4"
          >
            <div className="text-sm text-slate-500">
              <p>Need help? Contact us at vagneripg@gmail.com</p>
            </div>
          </motion.div>
        </motion.div>
      </div>
    </div>
  );
}
