"use client";
import React from "react";
import { Radar, IconContainer } from "./ui/radar-effect";
import { FileText, BarChart3, Share2, Database, ArrowUpRight, Zap } from "lucide-react";

export default function RadarEffectDemo() {
  return (
    <div className="flex min-h-screen w-full items-center justify-center bg-black">
      <div className="relative flex h-96 w-full max-w-3xl flex-col items-center justify-center space-y-4 overflow-hidden px-4">
        {/* Row 1 */}
        <div className="mx-auto w-full max-w-3xl">
          <div className="flex w-full items-center justify-center space-x-10 md:justify-between md:space-x-0">
            <IconContainer
              text="Web Development"
              delay={0.2}
              icon={<FileText className="h-8 w-8 text-slate-600" />}
            />
            <IconContainer
              delay={0.4}
              text="Mobile Apps"
              icon={<Zap className="h-8 w-8 text-slate-600" />}
            />
            <IconContainer
              text="API Design"
              delay={0.3}
              icon={<Database className="h-8 w-8 text-slate-600" />}
            />
          </div>
        </div>
        {/* Row 2 */}
        <div className="mx-auto w-full max-w-md">
          <div className="flex w-full items-center justify-center space-x-10 md:justify-between md:space-x-0">
            <IconContainer
              text="Maintenance"
              delay={0.5}
              icon={<BarChart3 className="h-8 w-8 text-slate-600" />}
            />
            <IconContainer
              text="Optimization"
              delay={0.8}
              icon={<ArrowUpRight className="h-8 w-8 text-slate-600" />}
            />
          </div>
        </div>
        {/* Row 3 */}
        <div className="mx-auto w-full max-w-3xl">
          <div className="flex w-full items-center justify-center space-x-10 md:justify-between md:space-x-0">
            <IconContainer
              delay={0.6}
              text="Integration"
              icon={<Share2 className="h-8 w-8 text-slate-600" />}
            />
            <IconContainer
              delay={0.7}
              text="Analytics"
              icon={<BarChart3 className="h-8 w-8 text-slate-600" />}
            />
          </div>
        </div>

        <Radar className="absolute -bottom-12" />
        <div className="absolute bottom-0 z-[41] h-px w-full bg-gradient-to-r from-transparent via-slate-700 to-transparent" />
      </div>
    </div>
  );
}
