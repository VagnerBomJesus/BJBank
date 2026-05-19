'use client';

import Link from 'next/link';
import { motion } from 'framer-motion';
import { Github, Mail } from 'lucide-react';

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1,
      delayChildren: 0.2,
    },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.5 },
  },
};

export function Footer() {
  return (
    <footer className="relative border-t border-slate-200 dark:border-slate-800 bg-gradient-to-b from-slate-50 to-slate-100 dark:from-slate-900/50 dark:to-slate-950">
      <div className="max-w-6xl mx-auto px-6 py-12 md:py-16">
        <motion.div
          className="grid md:grid-cols-4 gap-8 mb-12"
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, amount: 0.3 }}
        >
          {/* Brand */}
          <motion.div variants={itemVariants}>
            <motion.h3
              className="font-bold text-lg mb-4 bg-gradient-to-r from-bjbank-primary to-bjbank-secondary bg-clip-text text-transparent"
              whileHover={{ scale: 1.05 }}
            >
              BJBank
            </motion.h3>
            <p className="text-sm text-slate-600 dark:text-slate-400">
              Post-Quantum Cryptography in Mobile Banking Applications
            </p>
          </motion.div>

          {/* Documentation */}
          <motion.div variants={itemVariants}>
            <h4 className="font-semibold mb-4">Documentation</h4>
            <ul className="space-y-2 text-sm text-slate-600 dark:text-slate-400">
              {[
                { label: 'Getting Started', href: '/docs' },
                { label: 'Architecture', href: '/docs/architecture' },
                { label: 'Features', href: '/docs/features' },
                { label: 'PQC Guide', href: '/docs/pqc' },
              ].map((item, idx) => (
                <motion.li
                  key={idx}
                  whileHover={{ x: 4 }}
                  className="overflow-hidden"
                >
                  <Link
                    href={item.href}
                    className="hover:text-bjbank-primary transition-colors group relative"
                  >
                    <span className="relative">
                      {item.label}
                      <motion.span
                        className="absolute bottom-0 left-0 h-0.5 bg-bjbank-primary"
                        initial={{ width: 0 }}
                        whileHover={{ width: '100%' }}
                        transition={{ duration: 0.2 }}
                      />
                    </span>
                  </Link>
                </motion.li>
              ))}
            </ul>
          </motion.div>

          {/* Development */}
          <motion.div variants={itemVariants}>
            <h4 className="font-semibold mb-4">Development</h4>
            <ul className="space-y-2 text-sm text-slate-600 dark:text-slate-400">
              {[
                { label: 'Setup', href: '/docs/setup' },
                { label: 'Workflow', href: '/docs/workflow' },
                { label: 'Testing', href: '/docs/testing' },
                { label: 'Deployment', href: '/docs/deployment' },
              ].map((item, idx) => (
                <motion.li
                  key={idx}
                  whileHover={{ x: 4 }}
                  className="overflow-hidden"
                >
                  <Link
                    href={item.href}
                    className="hover:text-bjbank-accent transition-colors group relative"
                  >
                    <span className="relative">
                      {item.label}
                      <motion.span
                        className="absolute bottom-0 left-0 h-0.5 bg-bjbank-accent"
                        initial={{ width: 0 }}
                        whileHover={{ width: '100%' }}
                        transition={{ duration: 0.2 }}
                      />
                    </span>
                  </Link>
                </motion.li>
              ))}
            </ul>
          </motion.div>

          {/* Contact */}
          <motion.div variants={itemVariants}>
            <h4 className="font-semibold mb-4">Contact</h4>
            <div className="space-y-3">
              <p className="text-sm text-slate-600 dark:text-slate-400">
                <span className="font-medium">Author:</span><br />
                Vagner Bom Jesus
              </p>
              <p className="text-sm text-slate-600 dark:text-slate-400">
                <span className="font-medium">Institution:</span><br />
                Instituto Politécnico da Guarda
              </p>
            </div>
          </motion.div>
        </motion.div>

        {/* Divider */}
        <motion.div
          className="border-t border-slate-200 dark:border-slate-800 pt-8"
          variants={itemVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, amount: 0.5 }}
        >
          {/* Social Links */}
          <div className="flex justify-center gap-6 mb-8">
            {[
              {
                icon: Github,
                href: 'https://github.com/VagnerBomJesus/BJBank',
                label: 'GitHub',
              },
              {
                icon: Mail,
                href: 'mailto:vagneripg@gmail.com',
                label: 'Email',
              },
            ].map((social, idx) => {
              const Icon = social.icon;
              return (
                <motion.a
                  key={idx}
                  href={social.href}
                  target={social.href.startsWith('http') ? '_blank' : undefined}
                  rel={social.href.startsWith('http') ? 'noopener noreferrer' : undefined}
                  className="p-2 rounded-lg hover:bg-slate-200 dark:hover:bg-slate-800 transition-colors"
                  aria-label={social.label}
                  whileHover={{ scale: 1.2, rotate: 12 }}
                  whileTap={{ scale: 0.9 }}
                >
                  <Icon className="w-5 h-5" />
                </motion.a>
              );
            })}
          </div>

          {/* Copyright */}
          <motion.div
            className="text-center text-sm text-slate-600 dark:text-slate-400"
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            transition={{ delay: 0.3 }}
          >
            <p>&copy; 2026 BJBank. Master&apos;s Dissertation - Instituto Politécnico da Guarda</p>
            <p className="mt-2">Post-Quantum Cryptography in Mobile Banking Applications</p>
          </motion.div>
        </motion.div>
      </div>
    </footer>
  );
}
