package dev.utrpanic.dash

import android.Manifest
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.hasSetTextAction
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.isEnabled
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onAllNodesWithContentDescription
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import androidx.lifecycle.ViewModelProvider
import dev.utrpanic.dash.ui.home.DashDestination
import dev.utrpanic.dash.ui.home.DashViewModel
import org.junit.Assert.assertEquals
import androidx.test.espresso.Espresso.pressBack
import androidx.test.rule.GrantPermissionRule
import org.junit.Rule
import org.junit.Test
import org.junit.rules.RuleChain

class DashAppFlowTest {
    private val permissionRule = GrantPermissionRule.grant(
        Manifest.permission.ACCESS_FINE_LOCATION,
        Manifest.permission.ACCESS_COARSE_LOCATION,
    )
    private val composeRule = createAndroidComposeRule<MainActivity>()

    @get:Rule
    val rules: RuleChain = RuleChain.outerRule(permissionRule).around(composeRule)

    @Test
    fun editingFromHomeReturnsHomeForToolbarAndSystemBack() {
        composeRule.waitUntil(15_000) {
            composeRule.onAllNodes(hasContentDescription("현재 탑승 지점 편집") and isEnabled())
                .fetchSemanticsNodes().isNotEmpty()
        }

        composeRule.onNodeWithContentDescription("현재 탑승 지점 편집").performClick()
        assertBackStack(DashDestination.HOME, DashDestination.EDIT_BOARDING_POINT)
        composeRule.onNodeWithText("탑승 지점 편집").assertIsDisplayed()
        composeRule.onNodeWithContentDescription("뒤로").performClick()
        composeRule.onNodeWithContentDescription("현재 탑승 지점 편집").assertIsDisplayed()

        composeRule.onNodeWithContentDescription("현재 탑승 지점 편집").performClick()
        composeRule.onNodeWithText("정류장 추가").performClick()
        composeRule.onNodeWithTag("add-bus-stop-screen").assertIsDisplayed()
        pressBack()
        composeRule.onNodeWithText("탑승 지점 편집").assertIsDisplayed()
        pressBack()
        composeRule.onNodeWithContentDescription("현재 탑승 지점 편집").assertIsDisplayed()
    }

    @Test
    fun savingFromHomePopsEditorAndRecreationKeepsNestedStack() {
        composeRule.waitUntil(15_000) {
            composeRule.onAllNodes(hasContentDescription("현재 탑승 지점 편집") and isEnabled())
                .fetchSemanticsNodes().isNotEmpty()
        }
        composeRule.onNodeWithContentDescription("현재 탑승 지점 편집").performClick()
        composeRule.onNodeWithText("저장").performClick()
        composeRule.waitUntil(5_000) {
            composeRule.onAllNodesWithContentDescription("현재 탑승 지점 편집").fetchSemanticsNodes().isNotEmpty()
        }
        assertBackStack(DashDestination.HOME)

        composeRule.onNodeWithContentDescription("현재 탑승 지점 편집").performClick()
        val stopTag = composeRule.runOnIdle {
            val viewModel = ViewModelProvider(composeRule.activity)[DashViewModel::class.java]
            "edit-stop-${requireNotNull(viewModel.state.value.draft).routes.keys.first().id.storageKey}"
        }
        composeRule.onNodeWithTag(stopTag).performClick()
        composeRule.onNodeWithTag("select-bus-routes-screen").assertIsDisplayed()
        composeRule.activityRule.scenario.recreate()
        composeRule.onNodeWithTag("select-bus-routes-screen").assertIsDisplayed()
        assertBackStack(DashDestination.HOME, DashDestination.EDIT_BOARDING_POINT, DashDestination.SELECT_BUS_ROUTES)
        composeRule.onNodeWithText("완료").performClick()
        composeRule.onNodeWithText("탑승 지점 편집").assertIsDisplayed()
        assertBackStack(DashDestination.HOME, DashDestination.EDIT_BOARDING_POINT)
        pressBack()
        composeRule.onNodeWithContentDescription("현재 탑승 지점 편집").assertIsDisplayed()
        assertBackStack(DashDestination.HOME)
    }

    @Test
    fun managesBoardingPointsAndNavigatesThroughStopAndRouteSelection() {
        composeRule.waitUntil(15_000) {
            composeRule.onAllNodesWithContentDescription("탑승 지점 목록").fetchSemanticsNodes().isNotEmpty()
        }
        composeRule.onNodeWithContentDescription("탑승 지점 목록").performClick()
        composeRule.waitUntil(5_000) {
            composeRule.onAllNodesWithContentDescription("영등포역 편집").fetchSemanticsNodes().isNotEmpty()
        }

        composeRule.onNodeWithContentDescription("영등포역 삭제").performClick()
        composeRule.onNodeWithText("탑승 지점을 삭제할까요?").assertIsDisplayed()
        composeRule.onNodeWithText("취소").performClick()

        composeRule.onNodeWithContentDescription("탑승 지점 추가").performClick()
        composeRule.onNode(hasSetTextAction()).performTextInput("테스트 지점")
        composeRule.onNodeWithText("저장").performClick()
        composeRule.waitUntil(5_000) {
            composeRule.onAllNodesWithText("테스트 지점").fetchSemanticsNodes().isNotEmpty()
        }
        composeRule.onNodeWithText("테스트 지점").assertIsDisplayed()
        assertBackStack(DashDestination.HOME, DashDestination.BOARDING_POINTS)

        composeRule.onNodeWithContentDescription("영등포역 편집").performClick()
        composeRule.onNodeWithText("1개 · 5개 노선").assertIsDisplayed()
        composeRule.onNodeWithText("선택 노선").assertIsDisplayed()
        composeRule.onNodeWithTag("edit-stop-seoul-118000005-19005").performClick()
        composeRule.onNodeWithTag("select-bus-routes-screen").assertIsDisplayed()
        composeRule.onNodeWithText("5개 선택").assertIsDisplayed()

        pressBack()
        composeRule.onNodeWithText("정류장 추가").performClick()
        composeRule.onNodeWithTag("add-bus-stop-screen").assertIsDisplayed()
        composeRule.onNodeWithContentDescription("정류장 검색").assertIsDisplayed()
        pressBack()
        composeRule.onNodeWithText("탑승 지점 편집").assertIsDisplayed()
        pressBack()
        composeRule.onNodeWithContentDescription("탑승 지점 추가").assertIsDisplayed()

        composeRule.onNodeWithContentDescription("탑승 지점 추가").performClick()
        composeRule.onNodeWithContentDescription("뒤로").performClick()
        composeRule.onNodeWithContentDescription("탑승 지점 추가").assertIsDisplayed()
        assertBackStack(DashDestination.HOME, DashDestination.BOARDING_POINTS)
    }

    private fun assertBackStack(vararg destinations: DashDestination) {
        composeRule.runOnIdle {
            val viewModel = ViewModelProvider(composeRule.activity)[DashViewModel::class.java]
            assertEquals(destinations.toList(), viewModel.state.value.backStack)
        }
    }
}
