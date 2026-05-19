import { ModeToggle } from "@/components/ui/mode-toggle";

export default function Home() {
  return (
    <div className="flex flex-col justify-center items-center h-screen  gap-2">
      <h1 className="text-2xl">Happy coding!</h1>
      <ModeToggle />
    </div>
  );
}
