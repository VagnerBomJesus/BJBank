'use client';

import { motion } from 'framer-motion';
import Link from 'next/link';
import { ArrowRight, Zap, Shield, Code, BookOpen, Cpu, Github, Lock, Sparkles } from 'lucide-react';

const features = [
  {
    icon: Shield,
    title: 'Post-Quantum Cryptography',
    description: 'NIST-standardized Kyber KEM implementation with hybrid security',
    gradient: 'from-blue-500 to-cyan-500',
  },
  {
    icon: Code,
    title: 'Complete Banking System',
    description: 'Full-featured mobile app with 50+ features across 4 phases',
    gradient: 'from-purple-500 to-pink-500',
  },
  {
    icon: Zap,
    title: 'Production Ready',
    description: 'High-performance implementation optimized for mobile devices',
    gradient: 'from-amber-500 to-orange-500',
  },
];

const stats = [
  { number: '50+', label: 'Features', icon: Sparkles },
  { number: '4', label: 'Phases', icon: Code },
  { number: '80%+', label: 'Code Coverage', icon: Lock },
  { number: '2026', label: 'Master\'s Thesis', icon: BookOpen },
];

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.2,
      delayChildren: 0.3,
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

export default function Home() {
  return (
    <div className="relative overflow-hidden">
      {/* Ultra-sophisticated animated background */}
      <div className="fixed inset-0 -z-10">
        <div className="absolute inset-0 bg-gradient-to-br from-slate-900 via-blue-900/20 to-slate-900 dark:from-slate-950 dark:via-slate-900 dark:to-slate-950" />

        {/* Animated gradient orbs */}
        <motion.div
          animate={{
            top: ['0%', '50%', '100%'],
            left: ['0%', '50%', '0%'],
          }}
          transition={{ duration: 20, repeat: Infinity, ease: 'easeInOut' }}
          className="absolute top-0 right-0 h-[600px] w-[600px] rounded-full bg-gradient-primary opacity-15 blur-3xl dark:opacity-5"
        />

        <motion.div
          animate={{
            bottom: ['0%', '50%', '100%'],
            right: ['0%', '50%', '0%'],
          }}
          transition={{ duration: 25, repeat: Infinity, ease: 'easeInOut', delay: 5 }}
          className="absolute bottom-0 left-0 h-[600px] w-[600px] rounded-full bg-gradient-accent opacity-15 blur-3xl dark:opacity-5"
        />

        {/* Grid pattern overlay */}
        <div className="absolute inset-0 bg-grid-pattern opacity-5 dark:opacity-10" />
      </div>

      {/* Hero Section - Premium Design */}
      <section className="relative px-6 py-40 sm:py-52 md:py-60">
        <div className="mx-auto max-w-7xl">
          <motion.div
            variants={containerVariants}
            initial="hidden"
            animate="visible"
            className="text-center space-y-10"
          >
            {/* Animated badge with glow */}
            <motion.div variants={itemVariants} className="inline-block">
              <motion.div
                whileHover={{ scale: 1.05 }}
                className="glass px-6 py-3 rounded-full inline-block border border-blue-500/30 hover:border-blue-500/60 transition-colors backdrop-blur-xl bg-white/5"
              >
                <p className="text-sm font-semibold bg-gradient-to-r from-blue-400 to-cyan-400 bg-clip-text text-transparent">
                  ✨ Master&apos;s Dissertation 2026 • Instituto Politécnico da Guarda
                </p>
              </motion.div>
            </motion.div>

            {/* Premium title with animated gradient */}
            <motion.div variants={itemVariants} className="space-y-6">
              <h1 className="text-5xl sm:text-6xl md:text-7xl font-bold tracking-tight">
                <span className="block bg-gradient-to-r from-white via-blue-200 to-cyan-200 dark:from-white dark:via-blue-300 dark:to-cyan-300 bg-clip-text text-transparent leading-tight">
                  BJBank
                </span>
                <span className="block text-3xl sm:text-4xl md:text-5xl mt-4 bg-gradient-to-r from-bjbank-primary via-bjbank-secondary to-bjbank-accent bg-clip-text text-transparent">
                  Documentation Platform
                </span>
              </h1>
              <motion.p
                variants={itemVariants}
                className="text-xl md:text-2xl text-slate-300 dark:text-slate-400 max-w-3xl mx-auto leading-relaxed"
              >
                Post-Quantum Cryptography in Mobile Banking Applications
              </motion.p>
            </motion.div>

            {/* Premium CTA Buttons */}
            <motion.div
              variants={itemVariants}
              className="flex flex-col sm:flex-row gap-4 justify-center pt-10"
            >
              <motion.div
                whileHover={{ scale: 1.05, y: -2 }}
                whileTap={{ scale: 0.95 }}
              >
                <Link
                  href="/docs"
                  className="group relative px-10 py-4 rounded-xl font-bold flex items-center justify-center gap-3 bg-gradient-to-r from-bjbank-primary to-bjbank-secondary text-white overflow-hidden"
                >
                  <span className="absolute inset-0 bg-gradient-to-r from-white/0 via-white/30 to-white/0 translate-x-[-100%] group-hover:translate-x-[100%] transition-transform duration-500" />
                  <span className="relative flex items-center gap-2">
                    Explore Documentation
                    <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
                  </span>
                </Link>
              </motion.div>

              <motion.a
                whileHover={{ scale: 1.05, y: -2 }}
                whileTap={{ scale: 0.95 }}
                href="https://github.com/VagnerBomJesus/BJBank"
                target="_blank"
                rel="noopener noreferrer"
                className="px-10 py-4 rounded-xl font-bold flex items-center justify-center gap-3 glass border border-blue-500/30 hover:border-blue-500/60 transition-all text-white hover:bg-white/10"
              >
                <Github className="w-5 h-5" />
                View on GitHub
              </motion.a>
            </motion.div>
          </motion.div>
        </div>
      </section>

      {/* Features Section - Enhanced */}
      <section className="relative px-6 py-24 sm:py-32">
        <div className="mx-auto max-w-6xl">
          <motion.div
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            transition={{ duration: 0.8 }}
            className="text-center mb-20"
          >
            <h2 className="text-4xl md:text-5xl font-bold mb-6 bg-gradient-to-r from-white to-slate-300 dark:from-white dark:to-slate-400 bg-clip-text text-transparent">
              Core Capabilities
            </h2>
            <p className="text-lg text-slate-400 dark:text-slate-500 max-w-2xl mx-auto">
              Everything needed for secure mobile banking with quantum-resistant cryptography
            </p>
          </motion.div>

          <motion.div
            variants={containerVariants}
            initial="hidden"
            whileInView="visible"
            className="grid md:grid-cols-3 gap-8"
          >
            {features.map((feature, index) => {
              const Icon = feature.icon;
              return (
                <motion.div
                  key={index}
                  variants={itemVariants}
                  whileHover={{ y: -8, scale: 1.02 }}
                  className="group relative glass rounded-2xl p-8 border border-white/10 hover:border-white/30 transition-all duration-300 overflow-hidden"
                >
                  {/* Gradient border effect */}
                  <div className={`absolute inset-0 bg-gradient-to-r ${feature.gradient} opacity-0 group-hover:opacity-5 transition-opacity duration-300 -z-10`} />

                  {/* Icon with gradient background */}
                  <motion.div
                    whileHover={{ scale: 1.15, rotate: 12 }}
                    className={`w-16 h-16 rounded-2xl bg-gradient-to-br ${feature.gradient} text-white flex items-center justify-center mb-6 group-hover:shadow-glow transition-all`}
                  >
                    <Icon className="w-8 h-8" />
                  </motion.div>

                  <h3 className="text-xl font-bold mb-3 text-white group-hover:text-transparent group-hover:bg-gradient-to-r group-hover:bg-clip-text transition-all">{feature.title}</h3>
                  <p className="text-slate-400 group-hover:text-slate-300 transition-colors">{feature.description}</p>
                </motion.div>
              );
            })}
          </motion.div>
        </div>
      </section>

      {/* Stats Section - Premium */}
      <section className="relative px-6 py-24 sm:py-32">
        <div className="mx-auto max-w-6xl">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            className="glass rounded-3xl p-8 md:p-20 border border-white/10 relative overflow-hidden"
          >
            {/* Gradient background */}
            <div className="absolute inset-0 bg-gradient-to-r from-blue-500/5 via-transparent to-cyan-500/5 -z-10" />

            <div className="grid grid-cols-2 md:grid-cols-4 gap-8 md:gap-12 text-center">
              {stats.map((stat, index) => {
                const StatIcon = stat.icon;
                return (
                  <motion.div
                    key={index}
                    initial={{ opacity: 0, scale: 0.8 }}
                    whileInView={{ opacity: 1, scale: 1 }}
                    transition={{ delay: index * 0.15 }}
                    whileHover={{ scale: 1.1 }}
                  >
                    <motion.div
                      className="w-12 h-12 rounded-full bg-gradient-to-br from-bjbank-primary to-bjbank-accent flex items-center justify-center mb-4 mx-auto"
                      whileHover={{ rotate: 360 }}
                      transition={{ duration: 0.6 }}
                    >
                      <StatIcon className="w-6 h-6 text-white" />
                    </motion.div>
                    <div className="text-4xl md:text-5xl font-bold bg-gradient-to-r from-bjbank-primary to-bjbank-accent bg-clip-text text-transparent mb-2">
                      {stat.number}
                    </div>
                    <p className="text-sm md:text-base text-slate-400">{stat.label}</p>
                  </motion.div>
                );
              })}
            </div>
          </motion.div>
        </div>
      </section>

      {/* Quick Links - Enhanced */}
      <section className="relative px-6 py-24 sm:py-32">
        <div className="mx-auto max-w-6xl">
          <div className="grid md:grid-cols-2 gap-8">
            <motion.div
              initial={{ opacity: 0, x: -30 }}
              whileInView={{ opacity: 1, x: 0 }}
              whileHover={{ y: -8 }}
              className="glass rounded-3xl p-8 md:p-12 border border-white/10 hover:border-white/30 transition-all"
            >
              <div className="flex items-center gap-4 mb-8">
                <motion.div
                  whileHover={{ rotate: 360 }}
                  transition={{ duration: 0.6 }}
                  className="w-12 h-12 rounded-xl bg-gradient-to-br from-blue-500 to-cyan-500 flex items-center justify-center"
                >
                  <BookOpen className="w-6 h-6 text-white" />
                </motion.div>
                <h3 className="text-2xl font-bold">Documentation</h3>
              </div>
              <ul className="space-y-4">
                {[
                  { label: 'Introduction', href: '/docs/intro' },
                  { label: 'Architecture', href: '/docs/architecture' },
                  { label: 'Features', href: '/docs/features' },
                  { label: 'PQC Cryptography', href: '/docs/pqc' },
                ].map((link, idx) => (
                  <motion.li key={idx} whileHover={{ x: 8 }}>
                    <Link
                      href={link.href}
                      className="flex items-center gap-2 text-slate-300 hover:text-bjbank-primary transition-colors font-medium group"
                    >
                      <span className="w-1.5 h-1.5 rounded-full bg-bjbank-primary group-hover:scale-150 transition-transform" />
                      {link.label}
                      <ArrowRight className="w-4 h-4 ml-auto opacity-0 group-hover:opacity-100 transition-all" />
                    </Link>
                  </motion.li>
                ))}
              </ul>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, x: 30 }}
              whileInView={{ opacity: 1, x: 0 }}
              whileHover={{ y: -8 }}
              className="glass rounded-3xl p-8 md:p-12 border border-white/10 hover:border-white/30 transition-all"
            >
              <div className="flex items-center gap-4 mb-8">
                <motion.div
                  whileHover={{ rotate: 360 }}
                  transition={{ duration: 0.6 }}
                  className="w-12 h-12 rounded-xl bg-gradient-to-br from-purple-500 to-pink-500 flex items-center justify-center"
                >
                  <Cpu className="w-6 h-6 text-white" />
                </motion.div>
                <h3 className="text-2xl font-bold">Development</h3>
              </div>
              <ul className="space-y-4">
                {[
                  { label: 'Setup Guide', href: '/docs/setup' },
                  { label: 'Development Workflow', href: '/docs/workflow' },
                  { label: 'Testing', href: '/docs/testing' },
                  { label: 'Deployment', href: '/docs/deployment' },
                ].map((link, idx) => (
                  <motion.li key={idx} whileHover={{ x: 8 }}>
                    <Link
                      href={link.href}
                      className="flex items-center gap-2 text-slate-300 hover:text-bjbank-accent transition-colors font-medium group"
                    >
                      <span className="w-1.5 h-1.5 rounded-full bg-bjbank-accent group-hover:scale-150 transition-transform" />
                      {link.label}
                      <ArrowRight className="w-4 h-4 ml-auto opacity-0 group-hover:opacity-100 transition-all" />
                    </Link>
                  </motion.li>
                ))}
              </ul>
            </motion.div>
          </div>
        </div>
      </section>
    </div>
  );
}
