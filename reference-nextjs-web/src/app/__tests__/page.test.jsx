import "@testing-library/jest-dom";
import { render, screen } from "@testing-library/react";
import Home from "../page";

describe("Home", () => {
  it("renders a heading containing 'Happy coding'", () => {
    render(<Home />);

    const heading = screen.getByRole("heading", { level: 1 });

    expect(heading).toHaveTextContent("Happy coding");
  });
});
