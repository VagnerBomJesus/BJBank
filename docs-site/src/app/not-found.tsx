'use client';

import { motion } from 'framer-motion';
import Link from 'next/link';
import { ArrowRight, Home } from 'lucide-react';

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

export default function NotFound() {
  return (
    <div className="relative min-h-screen flex items-center justify-center overflow-hidden bg-gradient-to-br from-slate-950 via-blue-900/20 to-slate-950">
      {/* Animated background */}
      <div className="absolute inset-0 -z-10">
        <motion.div
          animate={{
            top: ['0%', '100%'],
            left: ['0%', '50%'],
          }}
          transition={{ duration: 20, repeat: Infinity, ease: 'easeInOut' }}
          className="absolute top-0 right-0 h-[600px] w-[600px] rounded-full bg-gradient-to-br from-red-500 to-orange-500 opacity-10 blur-3xl"
        />
        <motion.div
          animate={{
            bottom: ['0%', '100%'],
            right: ['0%', '50%'],
          }}
          transition={{ duration: 25, repeat: Infinity, ease: 'easeInOut', delay: 5 }}
          className="absolute bottom-0 left-0 h-[600px] w-[600px] rounded-full bg-gradient-to-tl from-pink-500 to-red-500 opacity-10 blur-3xl"
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
          {/* Animated 404 */}
          <motion.div variants={itemVariants}>
            <motion.div
              animate={{ rotate: 360 }}
              transition={{ duration: 8, repeat: Infinity, ease: 'linear' }}
              className="inline-block"
            >
              <div className="text-8xl md:text-9xl font-bold bg-gradient-to-r from-red-500 via-orange-500 to-pink-500 bg-clip-text text-transparent">
                404
              </div>
            </motion.div>
          </motion.div>

          {/* Title */}
          <motion.div variants={itemVariants} className="space-y-4">
            <h1 className="text-4xl md:text-5xl font-bold">Page Not Found</h1>
            <p className="text-xl text-slate-400">
              The page you&apos;re looking for doesn&apos;t exist. Let&apos;s get you back on track.
            </p>
          </motion.div>

          {/* Error Description */}
          <motion.div
            variants={itemVariants}
            className="glass rounded-2xl p-6 md:p-8 border border-white/10"
          >
            <p className="text-slate-300">
              It seems like you&apos;ve ventured into the quantum void. The page you&apos;re searching for
              either doesn&apos;t exist or has been quantum-encrypted beyond retrieval.
            </p>
          </motion.div>

          {/* CTA Buttons */}
          <motion.div
            variants={itemVariants}
            className="flex flex-col sm:flex-row gap-4 justify-center pt-4"
          >
            <motion.div
              whileHover={{ scale: 1.05, y: -2 }}
              whileTap={{ scale: 0.95 }}
            >
              <Link
                href="/"
                className="group relative px-10 py-4 rounded-xl font-bold flex items-center justify-center gap-3 bg-gradient-to-r from-bjbank-primary to-bjbank-secondary text-white overflow-hidden"
              >
                <span className="absolute inset-0 bg-gradient-to-r from-white/0 via-white/30 to-white/0 translate-x-[-100%] group-hover:translate-x-[100%] transition-transform duration-500" />
                <span className="relative flex items-center gap-2">
                  <Home className="w-5 h-5" />
                  Back to Home
                </span>
              </Link>
            </motion.div>

            <motion.div
              whileHover={{ scale: 1.05, y: -2 }}
              whileTap={{ scale: 0.95 }}
            >
              <Link
                href="/docs"
                className="px-10 py-4 rounded-xl font-bold flex items-center justify-center gap-3 glass border border-blue-500/30 hover:border-blue-500/60 transition-all text-white hover:bg-white/10"
              >
                <span className="relative flex items-center gap-2">
                  View Docs
                  <ArrowRight className="w-5 h-5" />
                </span>
              </Link>
            </motion.div>
          </motion.div>

          {/* Decorative elements */}
          <motion.div
            variants={itemVariants}
            className="pt-8 space-y-4"
          >
            <div className="text-sm text-slate-500">
              <p>Error Code: 404</p>
              <p>Resource: Not Found</p>
            </div>
          </motion.div>
        </motion.div>
      </div>
    </div>
  );
}
