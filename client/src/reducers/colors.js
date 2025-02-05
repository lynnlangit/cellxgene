import { ColorHelpers } from "../util/stateManager";

const ColorsReducer = (
  state = {
    colorMode: null,
    colorAccessor: null,
    rgb: null,
    scale: null
  },
  action,
  nextSharedState,
  prevSharedState
) => {
  switch (action.type) {
    case "initial data load complete (universe exists)":
    case "reset World to eq Universe": {
      const { world } = nextSharedState;
      const colorMode = null;
      const colorAccessor = null;
      const { rgb, scale } = ColorHelpers.createColors(world, colorMode);
      return {
        ...state,
        colorAccessor,
        colorMode,
        rgb,
        scale
      };
    }

    case "set clip quantiles":
    case "set World to current selection": {
      const { world: prevWorld, controls: prevControls } = prevSharedState;
      const resetColorState = ColorHelpers.checkIfColorByDiffexpAndResetColors(
        prevControls,
        state,
        prevWorld
      );
      if (resetColorState) {
        return resetColorState;
      }

      const { colorMode, colorAccessor } = state;
      const { world } = nextSharedState;
      const { rgb, scale } = ColorHelpers.createColors(
        world,
        colorMode,
        colorAccessor
      );
      return {
        ...state,
        rgb,
        scale
      };
    }

    case "reset colorscale": {
      return {
        ...state,
        ...ColorHelpers.resetColors(prevSharedState.world)
      };
    }

    case "color by categorical metadata":
    case "color by continuous metadata": {
      const { world } = prevSharedState;

      /* toggle between this mode and reset */
      const resetCurrent =
        action.type === state.colorMode &&
        action.colorAccessor === state.colorAccessor;
      const colorMode = !resetCurrent ? action.type : null;
      const colorAccessor = !resetCurrent ? action.colorAccessor : null;

      const { rgb, scale } = ColorHelpers.createColors(
        world,
        colorMode,
        colorAccessor
      );
      return {
        ...state,
        colorMode,
        colorAccessor,
        rgb,
        scale
      };
    }

    case "color by expression": {
      const { world } = prevSharedState;

      /* toggle between this mode and reset */
      const resetCurrent =
        action.type === state.colorMode && action.gene === state.colorAccessor;
      const colorMode = !resetCurrent ? action.type : null;
      const colorAccessor = !resetCurrent ? action.gene : null;

      const { rgb, scale } = ColorHelpers.createColors(
        world,
        colorMode,
        colorAccessor
      );
      return {
        ...state,
        colorMode,
        colorAccessor,
        rgb,
        scale
      };
    }

    case "clear differential expression": {
      const { world: prevWorld, controls: prevControls } = prevSharedState;
      const resetColorState = ColorHelpers.checkIfColorByDiffexpAndResetColors(
        prevControls,
        state,
        prevWorld
      );
      if (resetColorState) {
        return resetColorState;
      }
      return state;
    }

    default: {
      return state;
    }
  }
};

export default ColorsReducer;
