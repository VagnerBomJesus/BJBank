'use client';

import Link from 'next/link';
import { motion } from 'framer-motion';
import { BookOpen, ArrowRight, Code, Zap, Lock, Cpu } from 'lucide-react';

const docCategories = [
  {
    icon: BookOpen,
    title: 'Getting Started',
    description: 'Learn the basics of BJBank',
    gradient: 'from-blue-500 to-cyan-500',
    links: [
      { label: 'Introduction', href: '#intro' },
      { label: 'Quick Start', href: '#quickstart' },
      { label: 'Installation', href: '#install' },
    ],
  },
  {
    icon: Code,
    title: 'Core Concepts',
    description: 'Understand the architecture and design',
    gradient: 'from-purple-500 to-pink-500',
    links: [
      { label: 'Architecture Overview', href: '#architecture' },
      { label: 'Technology Stack', href: '#stack' },
      { label: 'Project Structure', href: '#structure' },
    ],
  },
  {
    icon: Zap,
    title: 'Features',
    description: 'Explore all implemented features',
    gradient: 'from-amber-500 to-orange-500',
    links: [
      { label: 'Phase 1: Core Banking', href: '#phase1' },
      { label: 'Phase 2: Advanced Services', href: '#phase2' },
      { label: 'Phase 3: Extended Features', href: '#phase3' },
    ],
  },
  {
    icon: Lock,
    title: 'Post-Quantum Cryptography',
    description: 'Deep dive into PQC implementation',
    gradient: 'from-emerald-500 to-teal-500',
    links: [
      { label: 'PQC Overview', href: '#pqc' },
      { label: 'Kyber KEM', href: '#kyber' },
      { label: 'Hybrid Security', href: '#hybrid' },
    ],
  },
];

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.15,
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

export default function DocsPage() {
  return (
    <div className="relative min-h-screen overflow-hidden bg-gradient-to-br from-slate-50 via-white to-slate-100 dark:from-slate-950 dark:via-slate-900 dark:to-slate-950">
      {/* Animated background */}
      <div className="fixed inset-0 -z-10">
        <motion.div
          animate={{
            top: ['0%', '50%', '100%'],
            left: ['0%', '50%', '0%'],
          }}
          transition={{ duration: 20, repeat: Infinity, ease: 'easeInOut' }}
          className="absolute top-0 right-0 h-[500px] w-[500px] rounded-full bg-blue-200 dark:bg-blue-900/20 opacity-20 blur-3xl dark:opacity-10"
        />
        <motion.div
          animate={{
            bottom: ['0%', '50%', '100%'],
            right: ['0%', '50%', '0%'],
          }}
          transition={{ duration: 25, repeat: Infinity, ease: 'easeInOut', delay: 5 }}
          className="absolute bottom-0 left-0 h-[500px] w-[500px] rounded-full bg-cyan-200 dark:bg-cyan-900/20 opacity-20 blur-3xl dark:opacity-10"
        />
      </div>

      <div className="relative z-10 max-w-6xl mx-auto px-6 py-16 md:py-24">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-center mb-20"
        >
          <motion.div
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.5 }}
          >
            <h1 className="text-5xl md:text-6xl font-bold mb-6 bg-gradient-to-r from-bjbank-primary via-bjbank-secondary to-bjbank-accent bg-clip-text text-transparent">
              Documentation
            </h1>
          </motion.div>
          <motion.p
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.2 }}
            className="text-xl text-slate-600 dark:text-slate-400 max-w-2xl mx-auto"
          >
            Complete guide to BJBank development and implementation
          </motion.p>
        </motion.div>

        {/* Doc Categories Grid */}
        <motion.div
          className="grid md:grid-cols-2 gap-8"
          variants={containerVariants}
          initial="hidden"
          animate="visible"
        >
          {docCategories.map((category, index) => {
            const Icon = category.icon;
            return (
              <motion.div
                key={index}
                variants={itemVariants}
                whileHover={{ y: -8, scale: 1.02 }}
                className="group relative glass rounded-2xl p-8 border border-white/10 hover:border-white/30 transition-all duration-300 overflow-hidden"
              >
                {/* Gradient border effect */}
                <div className={`absolute inset-0 bg-gradient-to-r ${category.gradient} opacity-0 group-hover:opacity-5 transition-opacity duration-300 -z-10`} />

                <div className="flex items-start gap-4 mb-6">
                  <motion.div
                    whileHover={{ scale: 1.15, rotate: 12 }}
                    className={`w-12 h-12 rounded-lg bg-gradient-to-br ${category.gradient} text-white flex items-center justify-center flex-shrink-0 group-hover:shadow-glow transition-all`}
                  >
                    <Icon className="w-6 h-6" />
                  </motion.div>
                  <div>
                    <h3 className="text-2xl font-bold group-hover:text-transparent group-hover:bg-gradient-to-r group-hover:bg-clip-text transition-all">{category.title}</h3>
                    <p className="text-slate-600 dark:text-slate-400 mt-1 group-hover:text-slate-300 transition-colors">{category.description}</p>
                  </div>
                </div>

                <ul className="space-y-3">
                  {category.links.map((link, linkIndex) => (
                    <motion.li
                      key={linkIndex}
                      initial={{ opacity: 0, x: -10 }}
                      animate={{ opacity: 1, x: 0 }}
                      transition={{ delay: index * 0.1 + linkIndex * 0.05 }}
                    >
                      <a
                        href={link.href}
                        className="group/link flex items-center gap-2 text-slate-600 dark:text-slate-400 hover:text-bjbank-primary transition-colors font-medium"
                      >
                        <span className="w-1.5 h-1.5 rounded-full bg-bjbank-primary group-hover/link:scale-150 transition-transform" />
                        {link.label}
                        <ArrowRight className="w-4 h-4 group-hover/link:translate-x-1 transition-transform opacity-0 group-hover/link:opacity-100" />
                      </a>
                    </motion.li>
                  ))}
                </ul>
              </motion.div>
            );
          })}
        </motion.div>

        {/* Coming Soon Section */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="mt-20 relative"
        >
          <motion.div
            className="glass rounded-3xl p-12 md:p-16 text-center border border-white/10 relative overflow-hidden"
            whileHover={{ borderColor: 'rgba(1, 117, 194, 0.3)' }}
          >
            {/* Animated gradient background */}
            <div className="absolute inset-0 bg-gradient-to-r from-blue-500/5 via-transparent to-cyan-500/5 -z-10" />

            <motion.h2
              initial={{ opacity: 0, scale: 0.8 }}
              whileInView={{ opacity: 1, scale: 1 }}
              className="text-3xl md:text-4xl font-bold mb-4 bg-gradient-to-r from-bjbank-primary to-bjbank-secondary bg-clip-text text-transparent"
            >
              📚 Full Documentation Coming Soon
            </motion.h2>
            <motion.p
              initial={{ opacity: 0 }}
              whileInView={{ opacity: 1 }}
              transition={{ delay: 0.1 }}
              className="text-lg text-slate-600 dark:text-slate-400 mb-8 max-w-2xl mx-auto"
            >
              Detailed documentation pages are being prepared. Check back soon for comprehensive guides on
              architecture, implementation, and best practices!
            </motion.p>
            <motion.div
              whileHover={{ scale: 1.05, y: -2 }}
              whileTap={{ scale: 0.95 }}
            >
              <Link
                href="/"
                className="inline-flex items-center gap-2 px-8 py-4 bg-gradient-to-r from-bjbank-primary to-bjbank-secondary text-white rounded-xl hover:shadow-glow transition-all font-bold group overflow-hidden relative"
              >
                <span className="absolute inset-0 bg-gradient-to-r from-white/0 via-white/30 to-white/0 translate-x-[-100%] group-hover:translate-x-[100%] transition-transform duration-500" />
                <span className="relative flex items-center gap-2">
                  Back to Home
                  <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
                </span>
              </Link>
            </motion.div>
          </motion.div>
        </motion.div>
      </div>
    </div>
  );
}
