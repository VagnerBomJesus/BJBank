import type { Config } from 'tailwindcss';

const config: Config = {
  darkMode: 'class',
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        bjbank: {
          primary: '#0175C2',
          secondary: '#02569B',
          accent: '#10B981',
          dark: '#0F172A',
          light: '#F8FAFC',
        },
      },
      backgroundImage: {
        'gradient-primary': 'linear-gradient(135deg, #0175C2 0%, #02569B 100%)',
        'gradient-accent': 'linear-gradient(135deg, #10B981 0%, #059669 100%)',
        'gradient-dark': 'linear-gradient(135deg, #0F172A 0%, #1E293B 100%)',
      },
      boxShadow: {
        'glow': '0 0 30px rgba(1, 117, 194, 0.3)',
        'glow-lg': '0 0 60px rgba(1, 117, 194, 0.4)',
      },
      animation: {
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'float': 'float 6s ease-in-out infinite',
        'shimmer': 'shimmer 2s linear infinite',
      },
      keyframes: {
        float: {
          '0%, 100%': { transform: 'translateY(0px)' },
          '50%': { transform: 'translateY(-20px)' },
        },
        shimmer: {
          '0%': { backgroundPosition: '-1000px 0' },
          '100%': { backgroundPosition: '1000px 0' },
        },
      },
    },
  },
  plugins: [
    require('@tailwindcss/typography'),
  ],
};

export default config;
