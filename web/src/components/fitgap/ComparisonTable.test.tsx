import { render, screen, within } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import ComparisonTable from "./ComparisonTable";
import type { SkillComparison } from "@/types";

// Baseline: what the table renders correctly today, before the revamp.
describe("ComparisonTable", () => {
  const comparisons = [
    { skill_label: "Communication", required_level: 3, candidate_level: 3, result: "match", delta: 0 },
    { skill_label: "SQL", required_level: 4, candidate_level: 2, result: "gap", delta: -2 },
  ] as SkillComparison[];

  it("renders one row per skill with its result badge", () => {
    render(<ComparisonTable comparisons={comparisons} />);

    const sqlRow = screen.getByText("SQL").closest("tr")!;
    expect(within(sqlRow).getByText(/Gap/)).toHaveTextContent("Gap -2");
    expect(screen.getByText("Communication").closest("tr")).toHaveTextContent("Match");
  });

  it("marks a skill the candidate was never assessed on", () => {
    render(
      <ComparisonTable
        comparisons={[{ skill_label: "Kubernetes", required_level: 2, result: "not_assessed" } as SkillComparison]}
      />,
    );

    expect(screen.getByText("Kubernetes").closest("tr")).toHaveTextContent("Not assessed");
  });
});
