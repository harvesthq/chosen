using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class TestDdl : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            List<ListItem> data = new List<ListItem>();
            data.Add(new ListItem());
            data.Add(new ListItem { Text = "opcija 1", Value = "1" });
            data.Add(new ListItem { Text = "opcija 2", Value = "2" });
            data.Add(new ListItem { Text = "opcija 3", Value = "3" });
            data.Add(new ListItem { Text = "opcija 4", Value = "4" });
            data.Add(new ListItem { Text = "opcija 5", Value = "5" });
            //cddlTest.DataSource = data;
            //cddlTest.DataTextField = "Text";
            //cddlTest.DataValueField = "Value";
            //cddlTest.DataBind();

            ecddl.DataSource = data;
            ecddl.DataTextField = "Text";
            ecddl.DataValueField = "Value";
            ecddl.DataBind();
        }
        List<string> sel = ecddl.SelectedValues;
    }

    protected void cddlTest_DataBinding(object sender, EventArgs e)
    {

    }
    protected void btnAction_Click(object sender, EventArgs e)
    {

    }
}